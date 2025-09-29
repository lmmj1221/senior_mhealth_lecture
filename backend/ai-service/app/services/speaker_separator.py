"""
화자 분리 서비스 - 시니어와 보호자 발화 구분
"""

import re
import logging
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class Speaker(Enum):
    """화자 유형"""
    SENIOR = "senior"  # 시니어 (엄마, 아버지)
    GUARDIAN = "guardian"  # 보호자 (아들, 딸)
    UNKNOWN = "unknown"  # 미분류


@dataclass
class SpeakerSegment:
    """화자별 발화 세그먼트"""
    speaker: Speaker
    text: str
    confidence: float = 0.0
    keywords_matched: List[str] = field(default_factory=list)


@dataclass
class SeparationResult:
    """화자 분리 결과"""
    senior_text: str
    guardian_text: str
    senior_segments: List[SpeakerSegment]
    guardian_segments: List[SpeakerSegment]
    separation_method: str
    confidence: float


class SpeakerSeparator:
    """화자 분리 클래스"""

    # 화자 식별 키워드
    SENIOR_INDICATORS = {
        # 시니어가 자주 사용하는 호칭
        "호칭": ["아들아", "딸아", "얘야", "우리 아들", "우리 딸", "자식아", "아가", "얘"],
        # 시니어가 사용하는 대명사
        "대명사": ["네가", "너는", "너도", "네", "너"],
        # 시니어 특유의 어미
        "어미": ["구나", "구먼", "네", "거니", "렴", "니", "더라", "던데", "거든"],
        # 시니어가 자주 사용하는 표현
        "표현": ["고맙다", "괜찮아", "그래", "알았어", "됐어", "어디 아프니", "밥은 먹었니"]
    }

    GUARDIAN_INDICATORS = {
        # 보호자가 사용하는 호칭
        "호칭": ["엄마", "어머니", "아버지", "아빠", "어머님", "아버님"],
        # 보호자가 사용하는 대명사
        "대명사": ["저는", "제가", "저도", "저예요"],
        # 보호자가 사용하는 존칭
        "어미": ["세요", "어요", "습니다", "시나요", "셨어요", "실까요", "드릴까요"],
        # 보호자가 자주 사용하는 표현
        "표현": ["어떠세요", "드셨어요", "괜찮으세요", "편하세요", "아프신 곳", "약 드셨어요"]
    }

    def __init__(self):
        """화자 분리 서비스 초기화"""
        self.methods = [
            self._separate_by_explicit_markers,
            self._separate_by_keywords,
            self._separate_by_sentence_patterns,
            self._separate_by_turn_taking
        ]

    def _calculate_senior_score(self, text: str) -> float:
        """텍스트의 시니어 화자 가능성 점수 계산"""
        if not text:
            return 0.0

        score = 0.0
        word_count = len(text.split())

        # 각 지표별 점수 계산
        for category, keywords in self.SENIOR_INDICATORS.items():
            for keyword in keywords:
                if keyword in text:
                    if category == "호칭":
                        score += 10  # 호칭이 가장 명확한 지표
                    elif category == "대명사":
                        score += 5
                    elif category == "어미":
                        score += 3
                    elif category == "표현":
                        score += 2
                    elif category == "문법":
                        score += 2

        # 보호자 지표가 있으면 감점
        for category, keywords in self.GUARDIAN_INDICATORS.items():
            for keyword in keywords:
                if keyword in text:
                    score -= 5

        # 정규화 (0-1 사이 값으로)
        normalized_score = max(0, min(1, score / (word_count * 0.5) if word_count > 0 else 0))
        return normalized_score

    def separate_speakers(self, text: str) -> SeparationResult:
        """
        텍스트에서 시니어와 보호자 발화를 분리

        Args:
            text: 전체 대화 텍스트

        Returns:
            SeparationResult: 화자별로 분리된 결과
        """
        logger.info(f"화자 분리 시작 - 텍스트 길이: {len(text)}")

        # 각 방법을 순서대로 시도
        for method in self.methods:
            result = method(text)
            if result and result.confidence > 0.3:  # 신뢰도 임계값
                logger.info(f"화자 분리 성공 - 방법: {result.separation_method}, 신뢰도: {result.confidence}")
                return result

        # 모든 방법이 실패한 경우
        logger.warning("화자 분리 실패 - 전체 텍스트를 시니어 발화로 간주")
        return self._create_default_result(text)

    def _separate_by_explicit_markers(self, text: str) -> Optional[SeparationResult]:
        """명시적 화자 표시를 기반으로 분리 (예: '엄마:', '아들:')"""

        pattern = r'(엄마|어머니|아버지|아빠|아들|딸|보호자|시니어)[:：]\s*([^:：\n]+)'
        matches = re.findall(pattern, text)

        if not matches:
            return None

        senior_segments = []
        guardian_segments = []

        for speaker_label, utterance in matches:
            segment = SpeakerSegment(
                speaker=Speaker.UNKNOWN,
                text=utterance.strip(),
                confidence=0.9  # 명시적 표시는 높은 신뢰도
            )

            if speaker_label in ["엄마", "어머니", "아버지", "아빠", "시니어"]:
                segment.speaker = Speaker.SENIOR
                senior_segments.append(segment)
            else:
                segment.speaker = Speaker.GUARDIAN
                guardian_segments.append(segment)

        if senior_segments or guardian_segments:
            return SeparationResult(
                senior_text=" ".join([s.text for s in senior_segments]),
                guardian_text=" ".join([s.text for s in guardian_segments]),
                senior_segments=senior_segments,
                guardian_segments=guardian_segments,
                separation_method="explicit_markers",
                confidence=0.9
            )

        return None

    def _separate_by_keywords(self, text: str) -> Optional[SeparationResult]:
        """키워드 기반 화자 분리"""

        # 문장 단위로 분리
        sentences = self._split_sentences(text)
        senior_segments = []
        guardian_segments = []

        for sentence in sentences:
            if not sentence.strip():
                continue

            senior_score = self._calculate_speaker_score(sentence, self.SENIOR_INDICATORS)
            guardian_score = self._calculate_speaker_score(sentence, self.GUARDIAN_INDICATORS)

            # 점수 차이가 명확한 경우만 분류
            if senior_score > guardian_score and senior_score > 0:
                segment = SpeakerSegment(
                    speaker=Speaker.SENIOR,
                    text=sentence,
                    confidence=senior_score / (senior_score + guardian_score) if guardian_score > 0 else senior_score
                )
                senior_segments.append(segment)
            elif guardian_score > senior_score and guardian_score > 0:
                segment = SpeakerSegment(
                    speaker=Speaker.GUARDIAN,
                    text=sentence,
                    confidence=guardian_score / (senior_score + guardian_score) if senior_score > 0 else guardian_score
                )
                guardian_segments.append(segment)

        if senior_segments or guardian_segments:
            avg_confidence = sum([s.confidence for s in senior_segments + guardian_segments]) / len(senior_segments + guardian_segments)
            return SeparationResult(
                senior_text=" ".join([s.text for s in senior_segments]),
                guardian_text=" ".join([s.text for s in guardian_segments]),
                senior_segments=senior_segments,
                guardian_segments=guardian_segments,
                separation_method="keyword_based",
                confidence=avg_confidence
            )

        return None

    def _separate_by_sentence_patterns(self, text: str) -> Optional[SeparationResult]:
        """문장 패턴 기반 화자 분리"""

        sentences = self._split_sentences(text)
        senior_segments = []
        guardian_segments = []

        for sentence in sentences:
            if not sentence.strip():
                continue

            # 존댓말 패턴 확인 (보호자)
            if re.search(r'(세요|습니다|어요|시나요|실까요)[\?\.]?$', sentence):
                segment = SpeakerSegment(
                    speaker=Speaker.GUARDIAN,
                    text=sentence,
                    confidence=0.7
                )
                guardian_segments.append(segment)
            # 반말 패턴 확인 (시니어)
            elif re.search(r'(구나|네|거니|니|더라|어|아)[\?\.]?$', sentence):
                segment = SpeakerSegment(
                    speaker=Speaker.SENIOR,
                    text=sentence,
                    confidence=0.7
                )
                senior_segments.append(segment)

        if senior_segments or guardian_segments:
            return SeparationResult(
                senior_text=" ".join([s.text for s in senior_segments]),
                guardian_text=" ".join([s.text for s in guardian_segments]),
                senior_segments=senior_segments,
                guardian_segments=guardian_segments,
                separation_method="sentence_patterns",
                confidence=0.7
            )

        return None

    def _separate_by_turn_taking(self, text: str) -> Optional[SeparationResult]:
        """대화 턴테이킹 기반 화자 분리"""

        sentences = self._split_sentences(text)
        if len(sentences) < 2:
            return None

        # 첫 문장에서 화자 추정
        first_speaker = self._identify_first_speaker(sentences[0])

        senior_segments = []
        guardian_segments = []

        for i, sentence in enumerate(sentences):
            if not sentence.strip():
                continue

            # 턴테이킹 가정: 홀수/짝수 번째로 화자 구분
            if first_speaker == Speaker.GUARDIAN:
                if i % 2 == 0:  # 짝수 인덱스 = 보호자
                    segment = SpeakerSegment(speaker=Speaker.GUARDIAN, text=sentence, confidence=0.5)
                    guardian_segments.append(segment)
                else:  # 홀수 인덱스 = 시니어
                    segment = SpeakerSegment(speaker=Speaker.SENIOR, text=sentence, confidence=0.5)
                    senior_segments.append(segment)
            else:
                if i % 2 == 0:  # 짝수 인덱스 = 시니어
                    segment = SpeakerSegment(speaker=Speaker.SENIOR, text=sentence, confidence=0.5)
                    senior_segments.append(segment)
                else:  # 홀수 인덱스 = 보호자
                    segment = SpeakerSegment(speaker=Speaker.GUARDIAN, text=sentence, confidence=0.5)
                    guardian_segments.append(segment)

        if senior_segments:
            return SeparationResult(
                senior_text=" ".join([s.text for s in senior_segments]),
                guardian_text=" ".join([s.text for s in guardian_segments]),
                senior_segments=senior_segments,
                guardian_segments=guardian_segments,
                separation_method="turn_taking",
                confidence=0.5
            )

        return None

    def _split_sentences(self, text: str) -> List[str]:
        """텍스트를 문장 단위로 분리"""
        # 다양한 문장 구분자로 분리
        sentences = re.split(r'[.!?。！？\n]+', text)
        return [s.strip() for s in sentences if s.strip()]

    def _calculate_speaker_score(self, sentence: str, indicators: Dict[str, List[str]]) -> float:
        """문장에서 특정 화자 지표 점수 계산"""
        score = 0.0
        matched_keywords = []

        for category, keywords in indicators.items():
            for keyword in keywords:
                if keyword in sentence:
                    # 카테고리별 가중치
                    weight = {
                        "호칭": 2.0,
                        "대명사": 1.5,
                        "어미": 1.0,
                        "표현": 1.2
                    }.get(category, 1.0)

                    score += weight
                    matched_keywords.append(keyword)

        # 정규화 (0-1 범위)
        return min(score / 5.0, 1.0)

    def _identify_first_speaker(self, first_sentence: str) -> Speaker:
        """첫 문장에서 화자 추정"""
        senior_score = self._calculate_speaker_score(first_sentence, self.SENIOR_INDICATORS)
        guardian_score = self._calculate_speaker_score(first_sentence, self.GUARDIAN_INDICATORS)

        if guardian_score > senior_score:
            return Speaker.GUARDIAN
        else:
            return Speaker.SENIOR

    def _create_default_result(self, text: str) -> SeparationResult:
        """기본 결과 생성 (전체를 시니어 발화로 간주)"""
        return SeparationResult(
            senior_text=text,
            guardian_text="",
            senior_segments=[SpeakerSegment(speaker=Speaker.SENIOR, text=text, confidence=0.1)],
            guardian_segments=[],
            separation_method="default",
            confidence=0.1
        )