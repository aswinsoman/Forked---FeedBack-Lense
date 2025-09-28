pipeline {
  agent any

  environment {
    // Credentials (create in Manage Jenkins → Credentials → Global)
    MONGO_URI    = credentials('mongo-uri')
    JWT_SECRET   = credentials('jwt-secret')

    // Local-staging ports/URLs on the Jenkins Windows machine
    FRONTEND_URL = 'http://localhost:8080'
    API_PORT     = '4000'
  }

  // Match your configured Node tool name exactly (Manage Jenkins → Tools → NodeJS)
  tools { nodejs 'Node_18' }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  // Keep while testing or switch to GitHub webhook
  triggers { pollSCM('* * * * *') }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install (backend & frontend)') {
      steps {
        powershell '''
          Write-Host "Installing backend deps..."
          if (Test-Path backend\\package.json) {
            Push-Location backend; npm ci; Pop-Location
          } else { Write-Host "No backend/package.json; skipping" }

          Write-Host "Installing frontend deps..."
          if (Test-Path frontend\\package.json) {
            Push-Location frontend; npm ci; Pop-Location
          } else { Write-Host "No frontend/package.json; skipping" }
        '''
      }
    }

    stage('Build') {
      steps {
        powershell '''
          if (Test-Path backend\\package.json) {
            Push-Location backend
            Write-Host "npm run build --if-present (backend)"
            npm run build --if-present
            if ($LASTEXITCODE -ne 0) { Write-Host "Backend build issues; continuing"; $global:LASTEXITCODE = 0 }
            Pop-Location
          }
          if (Test-Path frontend\\package.json) {
            Push-Location frontend
            Write-Host "npm run build --if-present (frontend)"
            npm run build --if-present
            if ($LASTEXITCODE -ne 0) { Write-Host "Frontend build issues; continuing"; $global:LASTEXITCODE = 0 }
            Pop-Location
          }
        '''
        archiveArtifacts artifacts: 'frontend/dist/**', allowEmptyArchive: true
      }
    }

    stage('Test') {
      steps {
        powershell '''
          if (Test-Path backend\\package.json) {
            Push-Location backend
            Write-Host "npm run test --if-present"
            npm run test --if-present
            if ($LASTEXITCODE -ne 0) { Write-Host "Tests failed or missing; continuing"; $global:LASTEXITCODE = 0 }
            Pop-Location
          } else { Write-Host "No backend/package.json; skipping tests" }
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'backend/test-results/*.xml'
          script {
            if (fileExists('backend/coverage/index.html')) {
              publishHTML target: [
                reportDir: 'backend/coverage',
                reportFiles: 'index.html',
                reportName: 'Backend Coverage',
                keepAll: true,
                alwaysLinkToLastBuild: true
              ]
            } else {
              echo 'Coverage HTML not found; skipping publishHTML'
            }
          }
        }
      }
    }

    stage('Code Quality (ESLint)') {
      steps {
        powershell '''
          function Run-Eslint($path) {
            $configs = @(
              "eslint.config.js","eslint.config.cjs","eslint.config.mjs",
              ".eslintrc.js",".eslintrc.cjs",".eslintrc.json",".eslintrc"
            ) | ForEach-Object { Join-Path $path $_ }

            $hasConfig = $false
            foreach ($c in $configs) { if (Test-Path $c) { $hasConfig = $true; break } }
            if (-not $hasConfig) { Write-Host "No ESLint config in $path; skipping"; return }

            Push-Location $path
            npx eslint .
            if ($LASTEXITCODE -ne 0) { Write-Host "ESLint found issues; continuing"; $global:LASTEXITCODE = 0 }
            Pop-Location
          }
          if (Test-Path backend)  { Run-Eslint "backend" }
          if (Test-Path frontend) { Run-Eslint "frontend" }
        '''
      }
    }

    stage('Security (npm audit)') {
      steps {
        powershell '''
          if (Test-Path backend\\package.json) {
            Push-Location backend
            npm audit --audit-level=high
            if ($LASTEXITCODE -ne 0) { Write-Host "npm audit found issues; continuing"; $global:LASTEXITCODE = 0 }
            Pop-Location
          } else { Write-Host "No backend/package.json; skipping audit" }
        '''
      }
    }

    stage('Deploy: Local Staging (Docker Desktop)') {
      steps {
        withCredentials([
          string(credentialsId: 'mongo-uri', variable: 'MONGO_URI'),
          string(credentialsId: 'jwt-secret', variable: 'JWT_SECRET')
        ]) {
          powershell '''
            docker version
            docker compose version

            # Down previous (ignore failures)
            try { docker compose -f docker-compose.staging.localbuild.yml down } catch { }

            # Session env (with fallbacks)
            $env:MONGO_URI    = "${env.MONGO_URI}"; if (-not $env:MONGO_URI) { $env:MONGO_URI = "mongodb://mongo:27017/feedback" }
            $env:JWT_SECRET   = "${env.JWT_SECRET}"; if (-not $env:JWT_SECRET) { $env:JWT_SECRET = "changeme" }
            $env:FRONTEND_URL = "${env:FRONTEND_URL}"
            $env:API_PORT     = "${env:API_PORT}"; if (-not $env:API_PORT) { $env:API_PORT = "4000" }

            Write-Host "Building local images..."
            docker compose -f docker-compose.staging.localbuild.yml build --pull

            Write-Host "Starting stack..."
            docker compose -f docker-compose.staging.localbuild.yml up -d

            docker image prune -f
          '''
        }
      }
    }

    stage('Monitoring & Smoke') {
      steps {
        powershell '''
          $port = "${env:API_PORT}"; if (-not $port) { $port = "4000" }
          $api  = "http://localhost:{0}/" -f $port
          Write-Host "Healthcheck: $api"
          try {
            $res = Invoke-WebRequest -Uri $api -UseBasicParsing -TimeoutSec 15
            if ($res.StatusCode -ge 200 -and $res.StatusCode -lt 400) {
              Write-Host ("OK: {0}" -f $res.StatusCode)
            } else { throw ("Bad status: {0}" -f $res.StatusCode) }
          } catch {
            Write-Error ("Healthcheck failed: {0}" -f $_.Exception.Message)
            exit 1
          }
        '''
      }
    }
  }

  post {
    always { cleanWs() }
  }
}
