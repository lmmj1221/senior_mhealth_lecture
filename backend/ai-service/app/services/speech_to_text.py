"""
Google Cloud Speech-to-Text API를 사용한 음성 인식 서비스
음성 파일을 텍스트로 변환하여 정신건강 분석에 활용
"""

import os
import logging
import tempfile
from typing import Optional, Dict, Any
from pathlib import Path
import io

from google.cloud import speech
from pydantic import BaseModel, Field
from pydub import AudioSegment

# 로깅 설정
logger = logging.getLogger(__name__)


class AudioRequest(BaseModel):
    """음성 분석 요청 모델"""
    user_id: str = Field(default="anonymous", description="사용자 ID")
    session_id: str = Field(default="", description="세션 ID")
    language_code: str = Field(default="ko-KR", description="언어 코드")


class TranscriptionResponse(BaseModel):
    """음성 인식 응답 모델"""
    transcript: str = Field(..., description="변환된 텍스트")
    confidence: float = Field(..., ge=0, le=1, description="인식 신뢰도")
    language_code: str = Field(..., description="인식된 언어")
    audio_duration: Optional[float] = Field(None, description="오디오 길이(초)")
    speaker_segments: Optional[list] = Field(None, description="화자별 세그먼트")
    senior_transcript: Optional[str] = Field(None, description="시니어 화자 텍스트")
    guardian_transcript: Optional[str] = Field(None, description="보호자 화자 텍스트")


class SpeechToTextService:
    """Google Cloud Speech-to-Text 서비스"""

    def __init__(self):
        """Speech-to-Text 서비스 초기화"""
        # GCP 프로젝트 설정 확인
        project_id = os.getenv('GCP_PROJECT_ID') or os.getenv('GOOGLE_CLOUD_PROJECT')
        if not project_id:
            raise ValueError("GCP_PROJECT_ID 또는 GOOGLE_CLOUD_PROJECT 환경변수가 설정되지 않았습니다")

        # Speech-to-Text 클라이언트 초기화
        self.client = speech.SpeechClient()
        
        # 지원하는 오디오 형식
        self.supported_formats = {
            '.wav': speech.RecognitionConfig.AudioEncoding.LINEAR16,
            '.mp3': speech.RecognitionConfig.AudioEncoding.MP3,
            '.m4a': speech.RecognitionConfig.AudioEncoding.MP3,  # M4A는 MP3로 처리
            '.flac': speech.RecognitionConfig.AudioEncoding.FLAC,
            '.ogg': speech.RecognitionConfig.AudioEncoding.OGG_OPUS,
        }

        logger.info("Google Cloud Speech-to-Text 서비스 초기화 완료")

    async def transcribe_audio(
        self,
        audio_content: bytes,
        filename: str,
        request: AudioRequest,
        storage_uri: str = None
    ) -> TranscriptionResponse:
        """음성 파일을 텍스트로 변환"""
        try:
            logger.info(f"음성 인식 시작 - 사용자: {request.user_id}, 파일: {filename}")

            # 파일 확장자 확인
            file_extension = Path(filename).suffix.lower()
            if file_extension not in self.supported_formats:
                raise ValueError(f"지원하지 않는 오디오 형식: {file_extension}")

            # Storage URI가 있으면 긴 오디오 처리 사용
            if storage_uri:
                logger.info(f"Storage URI 사용 - 긴 오디오 처리: {storage_uri}")
                return await self._transcribe_long_audio_from_storage(storage_uri, filename, request)

            # M4A 파일을 WAV로 변환
            if file_extension == '.m4a':
                logger.info("M4A 파일 감지 - WAV로 변환 중...")
                audio_segment = AudioSegment.from_file(io.BytesIO(audio_content), format="m4a")

                # WAV로 변환 (16-bit PCM, 16kHz 샘플레이트)
                wav_buffer = io.BytesIO()
                audio_segment = audio_segment.set_frame_rate(16000).set_channels(1).set_sample_width(2)
                audio_segment.export(wav_buffer, format="wav")
                audio_content = wav_buffer.getvalue()
                file_extension = '.wav'
                logger.info(f"WAV 변환 완료 - 크기: {len(audio_content)} bytes")

            # 오디오 크기 확인 (1분 이상이면 에러)
            if len(audio_content) > 10 * 1024 * 1024:  # 10MB 이상은 대부분 1분 초과
                raise ValueError("오디오가 너무 깁니다. Storage URI를 사용해주세요.")

            # 오디오 설정
            audio = speech.RecognitionAudio(content=audio_content)
            
            # 인식 설정 (화자 분리 기능 추가)
            config_params = {
                "encoding": speech.RecognitionConfig.AudioEncoding.LINEAR16 if file_extension == '.wav' else self.supported_formats[file_extension],
                "language_code": request.language_code,
                "enable_automatic_punctuation": True,  # 자동 구두점 추가
                "enable_word_time_offsets": False,     # 단어별 시간 정보 비활성화
                "model": "latest_long",                # 긴 오디오용 모델
                "use_enhanced": True,                  # 향상된 모델 사용
                "diarization_config": speech.SpeakerDiarizationConfig(
                    enable_speaker_diarization=True,
                    min_speaker_count=2,  # 최소 2명의 화자
                    max_speaker_count=3,  # 최대 3명의 화자
                ),
                "enable_separate_recognition_per_channel": False,
            }

            # WAV 파일은 샘플레이트 지정 (변환 시 16kHz로 설정했으므로)
            if file_extension == '.wav':
                config_params["sample_rate_hertz"] = 16000

            config = speech.RecognitionConfig(**config_params)

            # Speech-to-Text API 호출
            response = self.client.recognize(config=config, audio=audio)

            # 결과 처리
            if not response.results:
                logger.warning("음성 인식 결과가 없습니다")
                return TranscriptionResponse(
                    transcript="",
                    confidence=0.0,
                    language_code=request.language_code
                )

            # 전체 트랜스크립트 및 화자별 세그먼트 수집
            full_transcript = []
            speaker_segments = []
            total_confidence = 0.0
            result_count = 0

            for result in response.results:
                # 각 결과의 best alternative 가져오기
                best_alternative = result.alternatives[0]
                full_transcript.append(best_alternative.transcript)
                total_confidence += best_alternative.confidence
                result_count += 1

                # 화자 정보가 있는 경우 (words에 speaker_tag가 있음)
                if hasattr(best_alternative, 'words'):
                    for word_info in best_alternative.words:
                        if hasattr(word_info, 'speaker_tag'):
                            speaker_segments.append({
                                'word': word_info.word,
                                'speaker': word_info.speaker_tag,
                                'start_time': word_info.start_time.total_seconds() if hasattr(word_info, 'start_time') else None,
                                'end_time': word_info.end_time.total_seconds() if hasattr(word_info, 'end_time') else None
                            })

            # 전체 트랜스크립트 생성
            transcript = " ".join(full_transcript)
            avg_confidence = total_confidence / result_count if result_count > 0 else 0.0

            # 화자별 텍스트 분리
            senior_transcript, guardian_transcript = self._separate_speakers(speaker_segments, transcript)

            logger.info(f"음성 인식 완료 - 신뢰도: {avg_confidence:.2f}, 텍스트 길이: {len(transcript)}")
            if speaker_segments:
                logger.info(f"화자 분리 완료 - 총 {len(set(s['speaker'] for s in speaker_segments))}명의 화자 감지")

            return TranscriptionResponse(
                transcript=transcript,
                confidence=avg_confidence,
                language_code=request.language_code,
                speaker_segments=speaker_segments if speaker_segments else None,
                senior_transcript=senior_transcript,
                guardian_transcript=guardian_transcript
            )

        except Exception as e:
            logger.error(f"음성 인식 중 오류 발생: {str(e)}")
            raise Exception(f"음성 인식 실패: {str(e)}")

    async def _transcribe_long_audio_from_storage(
        self,
        storage_uri: str,
        filename: str,
        request: AudioRequest
    ) -> TranscriptionResponse:
        """Storage URI를 사용한 긴 오디오 처리 (LongRunningRecognize)"""
        try:
            logger.info(f"긴 오디오 인식 시작 - URI: {storage_uri}")

            # 파일 확장자 확인
            file_extension = Path(filename).suffix.lower()

            # M4A 파일은 먼저 다운로드하여 WAV로 변환 후 임시 Storage에 업로드
            if file_extension == '.m4a':
                logger.info("M4A 파일 감지 - Storage에서 다운로드 후 WAV 변환...")

                # Storage에서 파일 다운로드
                from google.cloud import storage
                storage_client = storage.Client()

                # URI에서 bucket과 blob path 추출 (gs://bucket-name/path/to/file)
                uri_parts = storage_uri.replace('gs://', '').split('/', 1)
                bucket_name = uri_parts[0]
                blob_path = uri_parts[1]

                bucket = storage_client.bucket(bucket_name)
                blob = bucket.blob(blob_path)
                audio_content = blob.download_as_bytes()

                logger.info(f"M4A 다운로드 완료: {len(audio_content)} bytes")

                # WAV로 변환
                audio_segment = AudioSegment.from_file(io.BytesIO(audio_content), format="m4a")
                wav_buffer = io.BytesIO()
                audio_segment = audio_segment.set_frame_rate(16000).set_channels(1).set_sample_width(2)
                audio_segment.export(wav_buffer, format="wav")
                wav_content = wav_buffer.getvalue()

                logger.info(f"WAV 변환 완료: {len(wav_content)} bytes")

                # 변환된 WAV를 임시 Storage 위치에 업로드
                temp_wav_path = blob_path.replace('.m4a', '_converted.wav')
                temp_blob = bucket.blob(temp_wav_path)
                temp_blob.upload_from_string(wav_content, content_type='audio/wav')

                logger.info(f"임시 WAV 업로드 완료: {temp_wav_path}")

                # 변환된 WAV URI 사용
                storage_uri = f"gs://{bucket_name}/{temp_wav_path}"
                audio = speech.RecognitionAudio(uri=storage_uri)
                encoding = speech.RecognitionConfig.AudioEncoding.LINEAR16
                sample_rate_hertz = 16000
            else:
                # M4A가 아닌 경우 Storage URI 직접 사용
                audio = speech.RecognitionAudio(uri=storage_uri)
                encoding = self.supported_formats.get(file_extension, speech.RecognitionConfig.AudioEncoding.LINEAR16)
                sample_rate_hertz = None

            # 인식 설정
            config_params = {
                "encoding": encoding,
                "language_code": request.language_code,
                "enable_automatic_punctuation": True,
                "model": "latest_long",
                "use_enhanced": True,
                "diarization_config": speech.SpeakerDiarizationConfig(
                    enable_speaker_diarization=True,
                    min_speaker_count=2,
                    max_speaker_count=3,
                ),
            }

            if sample_rate_hertz:
                config_params["sample_rate_hertz"] = sample_rate_hertz

            config = speech.RecognitionConfig(**config_params)

            # LongRunningRecognize API 호출
            logger.info("LongRunningRecognize API 호출 중...")
            operation = self.client.long_running_recognize(config=config, audio=audio)

            # 결과 대기 (최대 5분)
            logger.info("음성 인식 처리 중... (최대 5분 소요)")
            response = operation.result(timeout=300)

            # 결과 처리 (기존과 동일)
            if not response.results:
                logger.warning("음성 인식 결과가 없습니다")
                return TranscriptionResponse(
                    transcript="",
                    confidence=0.0,
                    language_code=request.language_code
                )

            # 전체 트랜스크립트 및 화자별 세그먼트 수집
            full_transcript = []
            speaker_segments = []
            total_confidence = 0.0
            result_count = 0

            for result in response.results:
                best_alternative = result.alternatives[0]
                full_transcript.append(best_alternative.transcript)
                total_confidence += best_alternative.confidence
                result_count += 1

                if hasattr(best_alternative, 'words'):
                    for word_info in best_alternative.words:
                        if hasattr(word_info, 'speaker_tag'):
                            speaker_segments.append({
                                'word': word_info.word,
                                'speaker': word_info.speaker_tag,
                                'start_time': word_info.start_time.total_seconds() if hasattr(word_info, 'start_time') else None,
                                'end_time': word_info.end_time.total_seconds() if hasattr(word_info, 'end_time') else None
                            })

            transcript = " ".join(full_transcript)
            avg_confidence = total_confidence / result_count if result_count > 0 else 0.0

            senior_transcript, guardian_transcript = self._separate_speakers(speaker_segments, transcript)

            logger.info(f"긴 오디오 인식 완료 - 신뢰도: {avg_confidence:.2f}, 텍스트 길이: {len(transcript)}")

            return TranscriptionResponse(
                transcript=transcript,
                confidence=avg_confidence,
                language_code=request.language_code,
                speaker_segments=speaker_segments if speaker_segments else None,
                senior_transcript=senior_transcript,
                guardian_transcript=guardian_transcript
            )

        except Exception as e:
            logger.error(f"긴 오디오 인식 중 오류: {str(e)}")
            raise Exception(f"긴 오디오 인식 실패: {str(e)}")

    def _separate_speakers(self, speaker_segments: list, full_transcript: str) -> tuple[str, str]:
        """화자별 텍스트 분리 - 시니어와 보호자 구분"""
        if not speaker_segments:
            # 화자 분리 정보가 없으면 키워드 기반으로 분리 시도
            from app.services.speaker_separator import SpeakerSeparator
            separator = SpeakerSeparator()
            result = separator.separate_speakers(full_transcript)
            return result.senior_text, result.guardian_text

        # 화자별로 단어 그룹화
        speakers_text = {}
        for segment in speaker_segments:
            speaker = segment['speaker']
            word = segment['word']

            if speaker not in speakers_text:
                speakers_text[speaker] = []
            speakers_text[speaker].append(word)

        # 화자별 텍스트 생성
        for speaker in speakers_text:
            speakers_text[speaker] = " ".join(speakers_text[speaker])

        # 화자가 2명인 경우 시니어/보호자 구분
        if len(speakers_text) == 2:
            speaker_list = list(speakers_text.keys())
            text1 = speakers_text[speaker_list[0]]
            text2 = speakers_text[speaker_list[1]]

            # 키워드 기반으로 누가 시니어인지 판단
            from app.services.speaker_separator import SpeakerSeparator
            separator = SpeakerSeparator()

            # 각 화자의 텍스트에서 시니어 지표 확인
            senior_score1 = separator._calculate_senior_score(text1)
            senior_score2 = separator._calculate_senior_score(text2)

            if senior_score1 > senior_score2:
                return text1, text2  # speaker1이 시니어
            else:
                return text2, text1  # speaker2가 시니어

        # 화자가 1명이거나 3명 이상인 경우
        elif len(speakers_text) == 1:
            # 1명이면 전체를 시니어로 간주
            return full_transcript, ""
        else:
            # 3명 이상이면 가장 많이 말한 사람을 시니어로 간주
            sorted_speakers = sorted(speakers_text.items(), key=lambda x: len(x[1]), reverse=True)
            return sorted_speakers[0][1], " ".join([s[1] for s in sorted_speakers[1:]])

    def get_supported_formats(self) -> list[str]:
        """지원하는 오디오 형식 목록 반환"""
        return list(self.supported_formats.keys())

    def validate_audio_file(self, filename: str, file_size: int) -> Dict[str, Any]:
        """오디오 파일 유효성 검사"""
        file_extension = Path(filename).suffix.lower()
        
        validation_result = {
            "is_valid": True,
            "errors": [],
            "warnings": []
        }

        # 파일 형식 확인
        if file_extension not in self.supported_formats:
            validation_result["is_valid"] = False
            validation_result["errors"].append(f"지원하지 않는 파일 형식: {file_extension}")

        # 파일 크기 확인 (10MB 제한)
        max_size = 10 * 1024 * 1024  # 10MB
        if file_size > max_size:
            validation_result["is_valid"] = False
            validation_result["errors"].append(f"파일 크기가 너무 큽니다: {file_size / (1024*1024):.1f}MB (최대 10MB)")

        # 경고사항
        if file_size > 5 * 1024 * 1024:  # 5MB 이상
            validation_result["warnings"].append("큰 파일은 처리 시간이 오래 걸릴 수 있습니다")

        return validation_result
