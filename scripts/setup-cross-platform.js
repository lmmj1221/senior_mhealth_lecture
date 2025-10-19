#!/usr/bin/env node

/**
 * 크로스플랫폼 프로젝트 설정 스크립트
 * Mac, Windows, Linux에서 동일하게 작동
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');
const os = require('os');
const readline = require('readline');

// 플랫폼 감지
const isWindows = os.platform() === 'win32';
const isMac = os.platform() === 'darwin';
const isLinux = os.platform() === 'linux';

// 색상 코드 (Windows에서는 기본 텍스트만 사용)
const isColorSupported = !isWindows && process.stdout.isTTY;
const colors = isColorSupported ? {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m'
} : {
  reset: '', red: '', green: '', yellow: '', blue: ''
};

// 유틸리티 함수들
function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// 파일 실행 권한 설정 (Unix-like 시스템)
function setExecutablePermission(filePath) {
  if (isWindows) return; // Windows에서는 필요 없음

  try {
    runCommand(`chmod +x "${filePath}"`, { ignoreError: true });
  } catch {
    // 권한 설정 실패해도 진행 가능
  }
}

function error(message) {
  log(`❌ ${message}`, 'red');
}

function success(message) {
  log(`✅ ${message}`, 'green');
}

function warning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function info(message) {
  log(`ℹ️  ${message}`, 'blue');
}

// 크로스플랫폼 명령어 실행
function runCommand(command, options = {}) {
  try {
    const result = execSync(command, {
      stdio: options.silent ? 'pipe' : 'inherit',
      encoding: 'utf8',
      ...options
    });
    return result;
  } catch (error) {
    if (!options.ignoreError) {
      throw error;
    }
    return null;
  }
}

// 사용자 입력 받기
function askQuestion(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// 플랫폼별 홈 디렉토리
function getHomeDir() {
  return os.homedir();
}

// 플랫폼별 경로 조인
function joinPath(...paths) {
  return path.join(...paths);
}

// 파일 존재 확인
function fileExists(filePath) {
  try {
    fs.accessSync(filePath, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

// 플랫폼별 브라우저 열기
function openBrowser(url) {
  const commands = {
    win32: `start "" "${url}"`,
    darwin: `open "${url}"`,
    linux: `xdg-open "${url}"`
  };

  const command = commands[os.platform()];
  if (command) {
    runCommand(command, { ignoreError: true });
  }
}

// 메뉴 출력
function showMenu() {
  log('\n===== Senior MHealth 크로스플랫폼 설정 도구 =====', 'blue');
  console.log('1. 환경 검증');
  console.log('2. Node.js 버전 관리 도구 설치');
  console.log('3. GCP CLI 설치');
  console.log('4. Firebase CLI 설치');
  console.log('5. Flutter SDK 설치 (선택사항)');
  console.log('6. 프로젝트 초기 설정');
  console.log('7. 개발 환경 테스트');
  console.log('8. VSC Extension 권장사항 표시');
  console.log('9. 프로젝트 정리');
  console.log('0. 종료');
}

// 환경 검증
function validateEnvironment() {
  log('\n🔍 개발 환경 검증 중...\n', 'blue');

  // Node.js 버전 체크
  try {
    const nodeVersion = runCommand('node --version', { silent: true }).trim();
    const nodeMajor = parseInt(nodeVersion.split('.')[0].replace('v', ''));
    if (nodeMajor >= 18) {
      success(`Node.js: ${nodeVersion}`);
    } else {
      warning(`Node.js: ${nodeVersion} (권장: 18.x 이상)`);
    }
  } catch {
    error('Node.js가 설치되지 않았습니다.');
    info('https://nodejs.org 에서 설치하세요.');
    return false;
  }

  // npm 버전 체크
  try {
    const npmVersion = runCommand('npm --version', { silent: true }).trim();
    const npmMajor = parseInt(npmVersion.split('.')[0]);
    if (npmMajor >= 8) {
      success(`npm: ${npmVersion}`);
    } else {
      warning(`npm: ${npmVersion} (권장: 8.x 이상)`);
    }
  } catch {
    error('npm이 설치되지 않았습니다.');
  }

  // Git 체크
  try {
    const gitVersion = runCommand('git --version', { silent: true }).trim();
    success(`Git: ${gitVersion}`);
  } catch {
    error('Git이 설치되지 않았습니다.');
    info('https://git-scm.com 에서 설치하세요.');
  }

  // Python 체크 (선택사항)
  try {
    const pythonVersion = runCommand('python --version', { silent: true });
    success(`Python: ${pythonVersion}`);
  } catch {
    try {
      const python3Version = runCommand('python3 --version', { silent: true });
      success(`Python3: ${python3Version}`);
    } catch {
      warning('Python이 설치되지 않았습니다 (선택사항)');
    }
  }

  // Flutter 체크 (선택사항)
  try {
    const flutterVersion = runCommand('flutter --version', { silent: true });
    const versionLine = flutterVersion.split('\n')[0];
    success(`Flutter: ${versionLine}`);
    info('Flutter doctor 실행으로 환경 확인 가능');
  } catch {
    warning('Flutter가 설치되지 않았습니다 (모바일 앱 개발 시 필요)');
    info('메뉴 5번에서 Flutter SDK 설치를 선택하세요.');
  }

  success('환경 검증 완료');
  return true;
}

// Volta (Node.js 버전 관리자) 설치
function installVolta() {
  log('\n📦 Node.js 버전 관리 도구 설치 중...\n', 'blue');

  if (isWindows) {
    info('Windows에서는 Volta 대신 nvm-windows를 권장합니다.');
    info('https://github.com/coreybutler/nvm-windows 에서 설치하세요.');
    return;
  }

  try {
    runCommand('curl https://get.volta.sh | bash', { stdio: 'inherit' });
    success('Volta 설치 완료');
    info('터미널을 재시작한 후 다음 명령어를 실행하세요:');
    info('volta install node@18');
    info('volta install npm@latest');
  } catch (error) {
    error(`Volta 설치 실패: ${error.message}`);
  }
}

// GCP CLI 설치
function installGcpCli() {
  log('\n☁️  GCP CLI 설치 중...\n', 'blue');

  if (isMac) {
    log('macOS에서 GCP CLI 설치...');
    try {
      runCommand('curl https://sdk.cloud.google.com | bash', { stdio: 'inherit' });
      success('GCP CLI 설치 완료');
      info('새 터미널에서 다음을 실행하세요: gcloud init');
    } catch (error) {
      error(`GCP CLI 설치 실패: ${error.message}`);
      info('수동 설치: https://cloud.google.com/sdk/docs/install');
    }
  } else if (isLinux) {
    log('Linux에서 GCP CLI 설치...');
    try {
      runCommand('curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz');
      runCommand('tar -xf google-cloud-cli-linux-x86_64.tar.gz');
      runCommand('./google-cloud-sdk/install.sh --quiet');
      success('GCP CLI 설치 완료');
      info('다음 명령을 실행하세요: ./google-cloud-sdk/bin/gcloud init');
    } catch (error) {
      error(`GCP CLI 설치 실패: ${error.message}`);
    }
  } else if (isWindows) {
    log('Windows에서 GCP CLI 설치...');
    info('https://cloud.google.com/sdk/docs/install 에서 GoogleCloudSDKInstaller.exe 다운로드 후 설치하세요.');
    openBrowser('https://cloud.google.com/sdk/docs/install');
  }
}

// Firebase CLI 설치
function installFirebaseCli() {
  log('\n🔥 Firebase CLI 설치 중...\n', 'blue');

  try {
    runCommand('npm install -g firebase-tools', { stdio: 'inherit' });
    success('Firebase CLI 설치 완료');
  } catch (error) {
    error('Firebase CLI 설치 실패');
    info('관리자 권한으로 다시 시도하거나 수동 설치하세요.');
  }
}

// Flutter SDK 설치
async function installFlutter() {
  log('\n📱 Flutter SDK 설치 및 환경 설정\n', 'blue');
  info('Flutter는 크로스플랫폼 모바일 앱 개발을 위한 Google의 UI 툴킷입니다.');
  console.log('');

  if (isMac) {
    console.log('🍺 macOS에서 Flutter 설치:');
    console.log('  1. Homebrew 확인: brew --version');
    console.log('  2. Flutter 설치: brew install flutter');
    console.log('  3. 환경 설정 확인: flutter doctor');

    // Homebrew 설치 확인 및 Flutter 설치 시도
    try {
      runCommand('brew --version', { silent: true });
      success('Homebrew 확인됨');

      warning('Flutter 설치는 수동으로 진행하는 것을 권장합니다.');
      warning('설치 도중 사용자 입력이 필요할 수 있습니다.');
      console.log('');
      info('수동 설치 명령어:');
      console.log('  brew install flutter');
      console.log('  flutter doctor');
    } catch {
      warning('Homebrew가 설치되지 않았습니다.');
      info('Homebrew 설치: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"');
    }
    return;
  }

  console.log('📋 Flutter 자동 설치 과정:');
  console.log('  1. Git으로 Flutter SDK 다운로드');
  console.log('  2. 환경변수 설정');
  console.log('  3. flutter doctor로 확인');
  console.log('');

  if (isWindows) {
    console.log('🪟 Windows에서 Flutter 설정:');

    // Chocolatey 확인 및 설치 시도
    try {
      runCommand('choco --version', { silent: true });
      success('Chocolatey 패키지 매니저 발견');

      const tryInstall = await askQuestion('Chocolatey로 Flutter 관련 도구 설치를 시도하시겠습니까? (y/N): ');
      if (tryInstall.toLowerCase() === 'y') {
        try {
          info('Android Studio 설치 중...');
          runCommand('choco install androidstudio -y', { stdio: 'inherit' });
          success('Android Studio 설치 완료');
        } catch (error) {
          warning('Android Studio 설치 실패, 수동 설치로 진행하세요.');
        }
      }
    } catch {
      warning('Chocolatey가 설치되지 않았습니다 (선택사항)');
    }

    info('Flutter SDK 수동 다운로드 링크:');
    console.log('  https://flutter.dev/docs/get-started/install/windows');
    openBrowser('https://flutter.dev/docs/get-started/install/windows');

  } else if (isLinux) {
    console.log('🐧 Linux에서 Flutter 설정:');

    // Snap 또는 수동 설치 옵션 제공
    console.log('');
    console.log('Snap으로 설치 (권장):');
    console.log('  sudo snap install flutter --classic');
    console.log('  flutter sdk-path  # PATH에 추가');
    console.log('');
    console.log('또는 수동 다운로드:');

    info('Flutter SDK 수동 다운로드 링크:');
    console.log('  https://flutter.dev/docs/get-started/install/linux');
    openBrowser('https://flutter.dev/docs/get-started/install/linux');
  }

  console.log('');
  info('모든 플랫폼 공통 - 설치 후 확인:');
  console.log('  flutter doctor              # 환경 진단');
  console.log('  flutter doctor --android-licenses  # Android 라이선스 동의');
  console.log('  flutter create my_app       # 새 프로젝트 생성');
  console.log('  cd my_app && flutter run    # 앱 실행');

  console.log('');
  info('Senior MHealth 모바일 앱 개발:');
  console.log('  frontend/mobile/ 디렉토리에 Flutter 프로젝트를 생성하세요.');
  console.log('  이 교육용 프로젝트에서는 학생들이 직접 Flutter 앱을 구현합니다.');
}

// 프로젝트 초기 설정
function setupProject() {
  // 기존 setup-project.sh 로직을 JavaScript로 포팅
  // ... 구현 예정
  warning('프로젝트 초기 설정은 곧 추가될 예정입니다.');
  info('현재는 setup-project.sh를 수동으로 실행하거나 Docker를 사용하세요.');
}

// 개발 환경 테스트
function testEnvironment() {
  log('\n🧪 개발 환경 테스트 중...\n', 'blue');

  const tests = [
    {
      name: 'Node.js 실행',
      command: 'node --version',
      success: 'Node.js 작동 중'
    },
    {
      name: 'npm 실행',
      command: 'npm --version',
      success: 'npm 작동 중'
    },
    {
      name: 'Firebase CLI',
      command: 'firebase --version',
      success: 'Firebase CLI 작동 중'
    },
    {
      name: 'GCP CLI',
      command: 'gcloud --version',
      success: 'GCP CLI 설치됨',
      optional: true
    },
    {
      name: 'Git',
      command: 'git --version',
      success: 'Git 작동 중'
    }
  ];

  tests.forEach(test => {
    try {
      runCommand(test.command, { silent: true });
      success(`${test.name}: ${test.success}`);
    } catch {
      if (test.optional) {
        warning(`${test.name}: 선택사항, 설치되지 않음`);
      } else {
        error(`${test.name}: 테스트 실패`);
      }
    }
  });
}

// VSC Extension 권장사항
function showVscodeExtensions() {
  log('\n🔧 VS Code 권장 확장 프로그램', 'blue');
  console.log('필수:');
  console.log('  - ms-vscode.vscode-json');
  console.log('  - ms-vscode.vscode-typescript-next');
  console.log('  - ms-vscode.vscode-eslint');
  console.log('  - esbenp.prettier-vscode');
  console.log('  - ms-vscode-remote.remote-containers (Dev Containers)');
  console.log('  - GitHub.copilot');

  console.log('\nFirebase 개발:');
  console.log('  - tobiassvn.firebase-explorer');
  console.log('  - pranayagarwal.firebase-adminsdk-generator');

  console.log('\nFlask/Python:');
  console.log('  - ms-python.python');
  console.log('  - ms-python.pylint');
  console.log('  - ms-python.black-formatter');

  console.log('\nDevOps:');
  console.log('  - ms-vscode.vscode-docker');
  console.log('  - ms-vscode.vscode-yaml');

  console.log('\n모바일 개발:');
  console.log('  - Dart-Code.dart-code');
  console.log('  - Dart-Code.flutter');

  info('Ctrl+Shift+X에서 위 확장 프로그램들을 검색하여 설치하세요.');
}

// 프로젝트 정리
function cleanupProject() {
  log('\n🧹 프로젝트 정리 중...\n', 'blue');

  const itemsToClean = [
    'node_modules',
    'frontend/web/node_modules',
    'backend/functions/node_modules',
    'frontend/mobile/node_modules',
    'dist',
    'build',
    '.firebase-cache',
    '.cache'
  ];

  itemsToClean.forEach(item => {
    if (fileExists(item)) {
      try {
        if (isWindows) {
          runCommand(`rmdir /s /q "${item}"`, { ignoreError: true });
        } else {
          runCommand(`rm -rf "${item}"`, { ignoreError: true });
        }
        success(`정리됨: ${item}`);
      } catch {
        warning(`건너뜀: ${item}`);
      }
    }
  });

  success('프로젝트 정리 완료');
}

// 메인 함수
async function main() {
  if (process.argv.length > 2) {
    // 명령행 인수로 직접 실행
    const command = process.argv[2];
    switch (command) {
      case 'validate':
        validateEnvironment();
        break;
      case 'test':
        testEnvironment();
        break;
      case 'cleanup':
        cleanupProject();
        break;
      default:
        console.log('사용법: node scripts/setup-cross-platform.js [validate|test|cleanup]');
    }
    return;
  }

  // 대화형 메뉴
  while (true) {
    showMenu();
    const choice = await askQuestion('\n선택하세요 (0-9): ');

    switch (choice) {
      case '1':
        validateEnvironment();
        break;
      case '2':
        installVolta();
        break;
      case '3':
        installGcpCli();
        break;
      case '4':
        installFirebaseCli();
        break;
      case '5':
        await installFlutter();
        break;
      case '6':
        setupProject();
        break;
      case '7':
        testEnvironment();
        break;
      case '8':
        showVscodeExtensions();
        break;
      case '9':
        cleanupProject();
        break;
      case '0':
        log('\n👋 안녕히 가세요!\n', 'green');
        process.exit(0);
      default:
        warning('올바른 메뉴를 선택하세요.');
    }

    // 각 명령어 후 일시 정지
    if (choice !== '0') {
      await askQuestion('\n계속하려면 Enter 키를 누르세요...');
    }
  }
}

// 초기화 및 실행 권한 설정
if (require.main === module) {
  // Unix-like 시스템에서 실행 권한 설정
  if (!isWindows) {
    setExecutablePermission(__filename);
  }

  // 메인 함수 실행
  main().catch(error => {
    log(`💥 오류 발생: ${error.message}`, 'red');
    process.exit(1);
  });
}

module.exports = {
  log,
  error,
  success,
  warning,
  info,
  runCommand,
  validateEnvironment,
  testEnvironment,
  cleanupProject,
  setExecutablePermission
};
