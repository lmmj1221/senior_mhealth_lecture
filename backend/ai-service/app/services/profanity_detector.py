"""
비속어 및 부적절한 언어 감지 서비스
"""
from typing import Dict, List, Tuple, Optional
import re
from dataclasses import dataclass
from enum import Enum


class Severity(Enum):
    """심각도 레벨"""
    NONE = "없음"
    LOW = "낮음"
    MEDIUM = "보통"
    HIGH = "높음"
    CRITICAL = "심각"


@dataclass
class ProfanityMatch:
    """감지된 비속어 정보"""
    word: str
    category: str
    severity: Severity
    position: int
    alternatives: List[str]


class ProfanityDetector:
    """한국어 비속어 및 부적절한 언어 감지기"""
    
    def __init__(self):
        """비속어 데이터베이스 초기화"""
        # 비속어 사전 (실제로는 더 많은 단어 필요)
        self.profanity_db = {
            # 욕설
            "개": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["저런", "안좋은"]},
            "개새끼": {"category": "욕설", "severity": Severity.CRITICAL, "alternatives": ["나쁜 사람", "못된 사람"]},
            "씨발": {"category": "욕설", "severity": Severity.CRITICAL, "alternatives": ["정말", "매우"]},
            "병신": {"category": "욕설", "severity": Severity.CRITICAL, "alternatives": ["어리석은", "바보같은"]},
            "미친": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["이상한", "엉뚱한"]},
            "죽어": {"category": "폭력적", "severity": Severity.CRITICAL, "alternatives": ["그만해", "멈춰"]},
            "죽여": {"category": "폭력적", "severity": Severity.CRITICAL, "alternatives": ["혼내줄", "야단칠"]},
            "꺼져": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["가줘", "물러가"]},
            "닥쳐": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["조용히 해", "그만 말해"]},
            "지랄": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["이상한 행동", "엉뚱한 짓"]},
            
            # 비속어 변형 (ㅅㅂ, ㅂㅅ 등)
            "ㅅㅂ": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["정말", "아이고"]},
            "ㅂㅅ": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["어리석은"]},
            "ㅈㄴ": {"category": "욕설", "severity": Severity.HIGH, "alternatives": ["매우", "정말"]},
            
            # 차별적 표현
            "장애인": {"category": "차별", "severity": Severity.MEDIUM, "alternatives": ["특별한 도움이 필요한 분"]},
            "정신병자": {"category": "차별", "severity": Severity.HIGH, "alternatives": ["정신적 어려움을 겪는 분"]},
            
            # 성적 비속어 (일부만 예시)
            "보지": {"category": "성적", "severity": Severity.CRITICAL, "alternatives": ["여성"]},
            "자지": {"category": "성적", "severity": Severity.CRITICAL, "alternatives": ["남성"]},
        }
        
        # 비속어 패턴 (정규표현식)
        self.profanity_patterns = [
            (r'개\s*새', Severity.CRITICAL, ["나쁜", "못된"]),
            (r'시\s*발', Severity.CRITICAL, ["정말", "매우"]),
            (r'병\s*신', Severity.CRITICAL, ["어리석은"]),
            (r'미\s*친', Severity.HIGH, ["이상한"]),
        ]
        
        # 문맥상 허용 가능한 경우 (예외 처리)
        self.allowed_contexts = {
            "개": ["개나리", "개발", "강아지", "반려견", "개월", "개선", "개량", "개편"],
        }
    
    def detect(self, text: str) -> Dict:
        """
        텍스트에서 비속어 및 부적절한 언어 감지
        
        Args:
            text: 분석할 텍스트
            
        Returns:
            감지 결과 딕셔너리
        """
        if not text:
            return self._empty_result()
        
        matches: List[ProfanityMatch] = []
        text_lower = text.lower()
        
        # 1. 정확한 단어 매칭
        for word, info in self.profanity_db.items():
            if self._should_detect_word(word, text_lower):
                # 모든 출현 위치 찾기
                positions = [m.start() for m in re.finditer(re.escape(word), text_lower)]
                for pos in positions:
                    matches.append(ProfanityMatch(
                        word=word,
                        category=info["category"],
                        severity=info["severity"],
                        position=pos,
                        alternatives=info["alternatives"]
                    ))
        
        # 2. 패턴 매칭
        for pattern, severity, alternatives in self.profanity_patterns:
            for match in re.finditer(pattern, text_lower):
                matches.append(ProfanityMatch(
                    word=match.group(),
                    category="욕설",
                    severity=severity,
                    position=match.start(),
                    alternatives=alternatives
                ))
        
        # 심각도별로 정렬
        matches.sort(key=lambda x: (
            self._severity_to_int(x.severity),
            x.position
        ), reverse=True)
        
        return self._format_result(text, matches)
    
    def _should_detect_word(self, word: str, text: str) -> bool:
        """
        단어가 감지되어야 하는지 판단 (예외 처리 포함)
        """
        if word not in text:
            return False
        
        # 예외 문맥 확인
        if word in self.allowed_contexts:
            for context in self.allowed_contexts[word]:
                if context in text:
                    return False
        
        return True
    
    def _severity_to_int(self, severity: Severity) -> int:
        """심각도를 숫자로 변환"""
        severity_map = {
            Severity.NONE: 0,
            Severity.LOW: 1,
            Severity.MEDIUM: 2,
            Severity.HIGH: 3,
            Severity.CRITICAL: 4
        }
        return severity_map.get(severity, 0)
    
    def _format_result(self, text: str, matches: List[ProfanityMatch]) -> Dict:
        """결과를 딕셔너리 형태로 포맷팅"""
        if not matches:
            return self._empty_result()
        
        # 가장 높은 심각도 결정
        max_severity = max(matches, key=lambda x: self._severity_to_int(x.severity)).severity
        
        # 카테고리별 분류
        by_category = {}
        for match in matches:
            category = match.category
            if category not in by_category:
                by_category[category] = []
            by_category[category].append({
                "word": match.word,
                "severity": match.severity.value,
                "position": match.position,
                "alternatives": match.alternatives
            })
        
        # 교정 제안 생성
        corrected_text = self._generate_corrected_text(text, matches)
        
        return {
            "has_profanity": True,
            "severity": max_severity.value,
            "total_count": len(matches),
            "matches": [
                {
                    "word": m.word,
                    "category": m.category,
                    "severity": m.severity.value,
                    "position": m.position,
                    "alternatives": m.alternatives
                }
                for m in matches
            ],
            "by_category": by_category,
            "corrected_text": corrected_text,
            "suggestions": self._generate_suggestions(matches)
        }
    
    def _empty_result(self) -> Dict:
        """비속어가 없을 때의 결과"""
        return {
            "has_profanity": False,
            "severity": Severity.NONE.value,
            "total_count": 0,
            "matches": [],
            "by_category": {},
            "corrected_text": None,
            "suggestions": []
        }
    
    def _generate_corrected_text(self, text: str, matches: List[ProfanityMatch]) -> str:
        """교정된 텍스트 생성"""
        corrected = text
        
        # 위치 역순으로 정렬하여 교체 (인덱스 변경 방지)
        sorted_matches = sorted(matches, key=lambda x: x.position, reverse=True)
        
        for match in sorted_matches:
            # 첫 번째 대체어 사용
            alternative = match.alternatives[0] if match.alternatives else "[수정필요]"
            corrected = (
                corrected[:match.position] +
                alternative +
                corrected[match.position + len(match.word):]
            )
        
        return corrected
    
    def _generate_suggestions(self, matches: List[ProfanityMatch]) -> List[str]:
        """개선 제안 생성"""
        suggestions = []
        
        severity_counts = {}
        for match in matches:
            severity = match.severity.value
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        if Severity.CRITICAL.value in severity_counts:
            suggestions.append(f"⚠️ 심각한 수준의 부적절한 언어가 {severity_counts[Severity.CRITICAL.value]}개 발견되었습니다.")
            suggestions.append("💡 상대방을 존중하는 표현으로 바꿔보세요.")
        
        if Severity.HIGH.value in severity_counts:
            suggestions.append(f"🔴 높은 수준의 부적절한 언어가 {severity_counts[Severity.HIGH.value]}개 발견되었습니다.")
            suggestions.append("💡 좀 더 부드러운 표현을 사용해주세요.")
        
        if Severity.MEDIUM.value in severity_counts:
            suggestions.append(f"🟡 중간 수준의 부적절한 언어가 {severity_counts[Severity.MEDIUM.value]}개 발견되었습니다.")
        
        # 카테고리별 제안
        categories = set(m.category for m in matches)
        if "욕설" in categories:
            suggestions.append("💬 욕설 대신 감정을 표현하는 다른 방법을 시도해보세요.")
        if "폭력적" in categories:
            suggestions.append("🕊️ 폭력적인 표현은 상대방에게 상처를 줄 수 있습니다.")
        if "차별" in categories:
            suggestions.append("🤝 모든 사람을 존중하는 표현을 사용해주세요.")
        
        return suggestions


# 전역 인스턴스
_detector = None


def get_detector() -> ProfanityDetector:
    """전역 ProfanityDetector 인스턴스 반환"""
    global _detector
    if _detector is None:
        _detector = ProfanityDetector()
    return _detector
