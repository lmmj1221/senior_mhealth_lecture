/**
 * 프로젝트 설정 로더 (Universal Configuration System)
 * 환경변수 기반 설정 (프론트엔드용)
 */

export interface ProjectConfig {
  project: {
    id: string
    name: string
    region: string
    location: string
  }
  firebase: {
    projectId: string
    storageBucket: string
    messagingSenderId: string
    appId?: string
    apiKey?: string
  }
  services: {
    aiService: {
      name: string
      url: string
    }
    apiService: {
      name: string
      url: string
    }
    webApp?: {
      url: string
    }
  }
  security?: {
    corsOrigins: string[]
    allowedDomains: string[]
  }
}

// 기본 설정 (fallback) - 환경변수로 덮어써야 합니다!
// ⚠️ 경고: 이 기본값은 플레이스홀더입니다. 실제 프로젝트 설정은 환경변수로 제공해야 합니다.
const DEFAULT_CONFIG: ProjectConfig = {
  project: {
    id: 'your-project-id',
    name: 'Your Project Name',
    region: 'us-central1',
    location: 'us-central1'
  },
  firebase: {
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.firebasestorage.app',
    messagingSenderId: 'your-messaging-sender-id',
    appId: 'your-firebase-app-id',
    apiKey: 'your-firebase-api-key'
  },
  services: {
    aiService: {
      name: 'your-ai-service',
      url: 'https://your-ai-service.run.app'
    },
    apiService: {
      name: 'your-api-service',
      url: 'https://your-api-service.run.app'
    },
    webApp: {
      url: 'https://your-app.vercel.app'
    }
  },
  security: {
    corsOrigins: [
      'http://localhost:3000',
      'http://localhost:3001'
    ],
    allowedDomains: [
      'localhost'
    ]
  }
}

let cachedConfig: ProjectConfig | null = null

// 파일 시스템 접근 제거 - 환경변수만 사용

/**
 * 환경변수로 설정 덮어쓰기
 */
function applyEnvironmentOverrides(config: ProjectConfig): ProjectConfig {
  // 환경변수가 있으면 덮어쓰기
  if (process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID) {
    config.project.id = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID
    config.firebase.projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID
  }

  if (process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET) {
    config.firebase.storageBucket = process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
  }

  if (process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID) {
    config.firebase.messagingSenderId = process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
  }

  if (process.env.NEXT_PUBLIC_FIREBASE_APP_ID) {
    config.firebase.appId = process.env.NEXT_PUBLIC_FIREBASE_APP_ID
  }

  if (process.env.NEXT_PUBLIC_FIREBASE_API_KEY) {
    config.firebase.apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY
  }

  if (process.env.NEXT_PUBLIC_API_URL) {
    config.services.apiService.url = process.env.NEXT_PUBLIC_API_URL
  }

  if (process.env.NEXT_PUBLIC_AI_SERVICE_URL) {
    config.services.aiService.url = process.env.NEXT_PUBLIC_AI_SERVICE_URL
  }

  if (process.env.NEXT_PUBLIC_APP_URL) {
    config.services.webApp = config.services.webApp || { url: '' }
    config.services.webApp.url = process.env.NEXT_PUBLIC_APP_URL
  }

  return config
}

/**
 * 설정을 재귀적으로 병합
 */
function mergeConfigs(base: any, override: any): any {
  const result = { ...base }

  for (const key in override) {
    if (override[key] !== null && typeof override[key] === 'object' && !Array.isArray(override[key])) {
      result[key] = mergeConfigs(result[key] || {}, override[key])
    } else {
      result[key] = override[key]
    }
  }

  return result
}

/**
 * 프로젝트 설정 가져오기 (환경변수 기반)
 */
export function getProjectConfig(): ProjectConfig {
  if (cachedConfig) {
    return cachedConfig
  }

  // 기본 설정으로 시작하고 환경변수로 덮어쓰기
  let config = { ...DEFAULT_CONFIG }
  config = applyEnvironmentOverrides(config)

  // ⚠️ 프로덕션 환경에서 플레이스홀더 값 검증
  if (process.env.NODE_ENV === 'production') {
    if (config.project.id === 'your-project-id' ||
        config.firebase.projectId === 'your-project-id') {
      throw new Error(
        '❌ 프로젝트 설정 오류\n\n' +
        '환경변수가 설정되지 않았습니다. 다음 환경변수를 설정해주세요:\n\n' +
        '  • NEXT_PUBLIC_FIREBASE_PROJECT_ID\n' +
        '  • NEXT_PUBLIC_FIREBASE_API_KEY\n' +
        '  • NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET\n' +
        '  • NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID\n' +
        '  • NEXT_PUBLIC_API_URL\n\n' +
        '자세한 내용은 SETUP_GUIDE.md를 참조하세요.'
      )
    }
  }

  // 개발 환경에서 경고 출력
  if (process.env.NODE_ENV === 'development' && config.project.id === 'your-project-id') {
    console.warn(
      '⚠️ 경고: 플레이스홀더 설정이 사용되고 있습니다.\n' +
      '.env 파일을 생성하고 실제 프로젝트 설정을 입력해주세요.'
    )
  }

  cachedConfig = config
  return config
}

/**
 * 특정 설정 값 가져오기 함수들
 */
export function getProjectId(): string {
  return getProjectConfig().project.id
}

export function getFirebaseConfig() {
  return getProjectConfig().firebase
}

export function getApiServiceUrl(): string {
  return getProjectConfig().services.apiService.url
}

export function getAiServiceUrl(): string {
  return getProjectConfig().services.aiService.url
}

export function getWebAppUrl(): string {
  return getProjectConfig().services.webApp?.url || 'http://localhost:3000'
}

export function getCorsOrigins(): string[] {
  return getProjectConfig().security?.corsOrigins || []
}

/**
 * 설정 다시 로드 (캐시 초기화)
 */
export function reloadProjectConfig(): ProjectConfig {
  cachedConfig = null
  return getProjectConfig()
}

/**
 * 개발 환경에서 설정 출력
 */
export function debugProjectConfig() {
  if (process.env.NODE_ENV === 'development') {
    console.log('🔧 프로젝트 설정:', {
      projectId: getProjectId(),
      apiUrl: getApiServiceUrl(),
      aiUrl: getAiServiceUrl(),
      webUrl: getWebAppUrl()
    })
  }
}