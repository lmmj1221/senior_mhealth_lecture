"""
Universal Configuration Loader for Senior MHealth Project
범용 설정 로더 - 환경변수 > 설정파일 > 기본값 순서로 로드

사용법:
    from config_loader import get_config, get_project_id, get_firebase_config

    # 전체 설정 로드
    config = get_config()
    project_id = config['project']['id']

    # 특정 값 바로 가져오기
    project_id = get_project_id()
    firebase_config = get_firebase_config()
"""

import os
import json
import logging
from typing import Dict, Any, Optional
from pathlib import Path

logger = logging.getLogger(__name__)

# 프로젝트 루트 경로 자동 감지
def get_project_root() -> Path:
    """프로젝트 루트 디렉토리 찾기 (project.config.json이 있는 곳)"""
    current = Path(__file__).parent
    while current != current.parent:
        if (current / 'project.config.json').exists():
            return current
        current = current.parent

    # 찾지 못하면 현재 파일 기준 상위 디렉토리 반환
    return Path(__file__).parent.parent


# 기본 설정 (fallback) - 환경변수로 덮어써야 합니다!
# ⚠️ 경고: 이 기본값은 플레이스홀더입니다. 실제 프로젝트 설정은 project.config.json 또는 환경변수로 제공해야 합니다.
DEFAULT_CONFIG = {
    "project": {
        "id": "your-project-id",
        "name": "Your Project Name",
        "region": "us-central1",
        "location": "us-central1"
    },
    "firebase": {
        "projectId": "your-project-id",
        "storageBucket": "your-project-id.firebasestorage.app",
        "messagingSenderId": "your-messaging-sender-id"
    },
    "database": {
        "cloudSqlConnectionName": "your-project-id:us-central1:your-db-instance",
        "cloudSqlInstance": "your-db-instance",
        "bigQueryDataset": "your_analytics_dataset"
    },
    "services": {
        "aiService": {
            "name": "your-ai-service",
            "url": "https://your-ai-service.run.app"
        },
        "apiService": {
            "name": "your-api-service",
            "url": "https://your-api-service.run.app"
        }
    }
}

def load_config_file() -> Dict[str, Any]:
    """설정 파일에서 설정 로드"""
    project_root = get_project_root()
    config_path = project_root / 'project.config.json'

    try:
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                logger.info(f"설정 파일 로드 성공: {config_path}")
                return config
        else:
            logger.warning(f"설정 파일을 찾을 수 없음: {config_path}")
            return {}
    except Exception as e:
        logger.error(f"설정 파일 로드 실패: {e}")
        return {}

def apply_env_overrides(config: Dict[str, Any]) -> Dict[str, Any]:
    """환경 변수로 설정 덮어쓰기"""

    # 프로젝트 설정
    if os.getenv('GOOGLE_CLOUD_PROJECT'):
        config.setdefault('project', {})['id'] = os.getenv('GOOGLE_CLOUD_PROJECT')
        config.setdefault('firebase', {})['projectId'] = os.getenv('GOOGLE_CLOUD_PROJECT')

    if os.getenv('PROJECT_REGION'):
        config.setdefault('project', {})['region'] = os.getenv('PROJECT_REGION')
        config.setdefault('project', {})['location'] = os.getenv('PROJECT_REGION')

    # Firebase 설정
    if os.getenv('FIREBASE_STORAGE_BUCKET'):
        config.setdefault('firebase', {})['storageBucket'] = os.getenv('FIREBASE_STORAGE_BUCKET')

    if os.getenv('FIREBASE_MESSAGING_SENDER_ID'):
        config.setdefault('firebase', {})['messagingSenderId'] = os.getenv('FIREBASE_MESSAGING_SENDER_ID')

    # 데이터베이스 설정
    if os.getenv('CLOUD_SQL_CONNECTION_NAME'):
        config.setdefault('database', {})['cloudSqlConnectionName'] = os.getenv('CLOUD_SQL_CONNECTION_NAME')

    if os.getenv('BIGQUERY_DATASET'):
        config.setdefault('database', {})['bigQueryDataset'] = os.getenv('BIGQUERY_DATASET')

    # 서비스 URL 설정
    if os.getenv('AI_SERVICE_URL'):
        config.setdefault('services', {}).setdefault('aiService', {})['url'] = os.getenv('AI_SERVICE_URL')

    if os.getenv('API_SERVICE_URL'):
        config.setdefault('services', {}).setdefault('apiService', {})['url'] = os.getenv('API_SERVICE_URL')

    if os.getenv('WEB_APP_URL'):
        config.setdefault('services', {}).setdefault('webApp', {})['url'] = os.getenv('WEB_APP_URL')

    return config

def merge_configs(base_config: Dict[str, Any], override_config: Dict[str, Any]) -> Dict[str, Any]:
    """설정을 재귀적으로 병합"""
    result = base_config.copy()

    for key, value in override_config.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = merge_configs(result[key], value)
        else:
            result[key] = value

    return result

# 전역 설정 캐시
_cached_config: Optional[Dict[str, Any]] = None

def get_config(force_reload: bool = False) -> Dict[str, Any]:
    """
    설정 로드 (우선순위: 환경변수 > 설정파일 > 기본값)

    Args:
        force_reload: 캐시 무시하고 다시 로드

    Returns:
        Dict: 최종 설정
    """
    global _cached_config

    if _cached_config is not None and not force_reload:
        return _cached_config

    # 1. 기본 설정으로 시작
    config = DEFAULT_CONFIG.copy()

    # 2. 설정 파일로 덮어쓰기
    file_config = load_config_file()
    if file_config:
        config = merge_configs(config, file_config)

    # 3. 환경 변수로 최종 덮어쓰기
    config = apply_env_overrides(config)

    # ⚠️ 프로덕션 환경에서 플레이스홀더 값 검증
    environment = os.getenv('ENVIRONMENT', 'development')
    if environment == 'production' and config['project']['id'] == 'your-project-id':
        error_msg = (
            "❌ 프로젝트 설정 오류\n\n"
            "환경변수가 설정되지 않았습니다. 다음 환경변수를 설정해주세요:\n\n"
            "  • GOOGLE_CLOUD_PROJECT (또는 GCP_PROJECT_ID)\n"
            "  • PROJECT_REGION\n"
            "  • FIREBASE_STORAGE_BUCKET\n"
            "  • CLOUD_SQL_CONNECTION_NAME\n"
            "  • AI_SERVICE_URL\n"
            "  • API_SERVICE_URL\n\n"
            "또는 project.config.json 파일을 생성하세요.\n"
            "자세한 내용은 SETUP_GUIDE.md를 참조하세요."
        )
        logger.error(error_msg)
        raise ValueError(error_msg)

    # 개발 환경에서 경고 출력
    if environment == 'development' and config['project']['id'] == 'your-project-id':
        logger.warning(
            "⚠️ 경고: 플레이스홀더 설정이 사용되고 있습니다.\n"
            "project.config.json 파일을 생성하거나 환경변수를 설정해주세요."
        )

    _cached_config = config
    logger.info("설정 로드 완료")
    return config

# 편의 함수들
def get_project_id() -> str:
    """프로젝트 ID 가져오기"""
    return get_config()['project']['id']

def get_project_region() -> str:
    """프로젝트 리전 가져오기"""
    return get_config()['project']['region']

def get_firebase_config() -> Dict[str, Any]:
    """Firebase 설정 가져오기"""
    return get_config()['firebase']

def get_database_config() -> Dict[str, Any]:
    """데이터베이스 설정 가져오기"""
    return get_config()['database']

def get_cloud_sql_connection_name() -> str:
    """Cloud SQL 연결 이름 가져오기"""
    return get_config()['database']['cloudSqlConnectionName']

def get_bigquery_dataset() -> str:
    """BigQuery 데이터셋 이름 가져오기"""
    return get_config()['database']['bigQueryDataset']

def get_ai_service_url() -> str:
    """AI 서비스 URL 가져오기"""
    return get_config()['services']['aiService']['url']

def get_api_service_url() -> str:
    """API 서비스 URL 가져오기"""
    return get_config()['services']['apiService']['url']

def get_web_app_url() -> str:
    """웹 앱 URL 가져오기"""
    return get_config()['services'].get('webApp', {}).get('url', 'http://localhost:3000')

def get_cors_origins() -> list:
    """CORS 허용 오리진 목록 가져오기"""
    return get_config().get('security', {}).get('corsOrigins', [
        'http://localhost:3000',
        'http://localhost:3001'
    ])

def reload_config():
    """설정 다시 로드 (캐시 초기화)"""
    global _cached_config
    _cached_config = None
    return get_config(force_reload=True)

# 설정 검증 함수
def validate_config() -> bool:
    """설정 유효성 검사"""
    try:
        config = get_config()

        # 필수 필드 확인
        required_fields = [
            ['project', 'id'],
            ['project', 'region'],
            ['firebase', 'projectId'],
            ['database', 'cloudSqlConnectionName']
        ]

        for field_path in required_fields:
            current = config
            for field in field_path:
                if field not in current:
                    logger.error(f"필수 설정 누락: {'.'.join(field_path)}")
                    return False
                current = current[field]

        logger.info("설정 검증 성공")
        return True

    except Exception as e:
        logger.error(f"설정 검증 실패: {e}")
        return False

if __name__ == "__main__":
    # 테스트 실행
    logging.basicConfig(level=logging.INFO)

    print("=== Senior MHealth 설정 로더 테스트 ===")

    if validate_config():
        config = get_config()
        print(f"프로젝트 ID: {get_project_id()}")
        print(f"프로젝트 리전: {get_project_region()}")
        print(f"AI 서비스 URL: {get_ai_service_url()}")
        print(f"웹 앱 URL: {get_web_app_url()}")
        print("설정 로드 성공! ✅")
    else:
        print("설정 검증 실패! ❌")