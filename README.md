# ✈️ DipAir

**“이번 주, 어디로 떠날까?”**  
출발 공항과 예산만 정하면, 이번 주·다음 주에 갈 수 있는 **최저가 항공권 목적지**를 추천해 주는 iOS 앱입니다.  
단기(1~4주) 항공권 가격에 집중해서, “언제 / 어디로 가면 상대적으로 싸게 갈 수 있는지”를 직관적으로 보여주는 것이 목표입니다.

> ⚠️ 현재는 **Amadeus Test API** 기반의 **MVP 프로토타입**입니다.  
> 실제 발권/예약은 외부 서비스(예: 항공권 검색 사이트)로 이동하는 것을 전제로 합니다.

---

## 🌟 주요 기능 (MVP)

### 1. 홈(Home) – “이번 주, 어디로 떠날까요?”
- 상단에 오늘 날짜와 앱 타이틀 **DipAir**
- **출발 공항 선택**
  - 기본 옵션: `인천 ICN / 김포 GMP / 부산 PUS`
  - + 사용자가 직접 입력하는 IATA 코드(예: `MAD`, `BOS`, `LHR`)도 처리 가능하도록 설계
- **예산 슬라이더**
  - “예산: 약 5,000,000원 이하” 등으로 표시
  - 내부적으로 Amadeus `maxPrice` 파라미터로 전달
- **항공권 추천 리스트**
  - Amadeus **Flight Inspiration Search**  
    `/v1/shopping/flight-destinations` 결과를 파싱해서
  - **이번 주 / 다음 주** 두 개의 섹션으로 나누어 카드 리스트로 표시
  - 각 카드에는:
    - 목적지 공항 코드 + 도시 이름
    - 출발일 / 귀국일
    - 총액(통화 포함)
- **에러 / 빈 상태 처리**
  - API 400/500/429 응답 시,  
    - 콘솔에 상세 로그 출력
    - 화면에는 “표시할 항공권이 없습니다. 예산이나 출발지를 바꿔보세요.” 등의 안내 문구 표시
  - Amadeus 서버 오류가 잦은 테스트 환경 특성을 고려해, **데모용 더미 데이터**로도 동작하도록 구현

### 2. 상세(Detail) – 특정 목적지 가격 히스토리
- 홈에서 특정 딜을 탭하면 상세화면으로 이동
- 해당 목적지에 대해:
  - **4~8주 구간**의 날짜별 최저가를 Amadeus **Flight Dates** API로 조회  
    `/v1/shopping/flight-dates`
  - 결과를 `PriceHistory` 모델로 변환해 **최근 8개 구간 히스토리**를 표시
- (MVP) 단순 리스트/통계
  - 최소가, 최대가, 평균가 같은 간단한 통계 값
  - 테스트 환경에서 데이터가 없을 경우를 대비해 **더미 히스토리** 생성 로직 포함

### 3. 분석(Analysis) – 가격 흐름 요약 (MVP 수준)
- 전체 히스토리 데이터를 모아서:
  - “이번 주 vs 다음 주 평균 가격”
  - “가장 저렴한 목적지 Top N”
- 현재는 구조만 잡아 둔 상태로, 추후 그래프/차트(Recharts 등) 연동 예정

---

## 🧱 아키텍처 & 기술 스택

- **언어**: Swift 5
- **UI**: SwiftUI
- **아키텍처**: MVVM
  - `View` ⇄ `ViewModel` ⇄ `Service`
- **네트워킹**: `URLSession` + `async/await`
- **외부 API**: [Amadeus for Developers – Test Environment](https://developers.amadeus.com/)
  - `POST /v1/security/oauth2/token`
  - `GET /v1/shopping/flight-destinations`
  - `GET /v1/shopping/flight-dates`
- **기타**
  - 토큰 캐싱 + 만료시간 관리
  - 에러 핸들링 및 Rate Limit(429) 대응 로깅
  - API 키/시크릿은 **로컬 파일 + .gitignore**로 관리

---

## 📁 프로젝트 구조

```text
DipAir/
└─
   ├─ APP/
   │   └─ FlightDealFinderApp.swift      # 앱 진입점 (TabView: Home / Booking / Analysis)
   │
   ├─ Config/
   │   └─ APIConfiguration.swift        # 로컬에서만 존재, .gitignore 처리
   │
   ├─ Models/
   │   ├─ Airport.swift                 # 공항 / IATA 코드 정의
   │   ├─ FlightDeal.swift              # 화면에서 사용하는 가공된 항공권 모델
   │   └─ priceHistory.swift            # 상세 화면용 가격 히스토리 모델
   │
   ├─ Services/
   │   └─ AmadeusService.swift          # OAuth + Flight Inspiration / Dates API 호출
   │
   ├─ ViewModels/
   │   ├─ HomeViewModel.swift           # 홈 화면 상태, API 호출, 에러 처리
   │   ├─ DetailViewModel.swift         # 상세 화면 가격 히스토리 로딩, 통계 계산
   │   └─ AnalysisViewModel.swift       # 향후 분석 탭용 (MVP 구조)
   │
   ├─ Views/
   │   ├─ ContentView.swift             # TabView 구성
   │   ├─ HomeView.swift                # 출발지/예산 선택 + 추천 리스트
   │   ├─ DealCard.swift                # 리스트에서 쓰는 항공권 카드 UI
   │   ├─ DetailView.swift              # 가격 히스토리/통계 화면
   │   ├─ BookingView.swift             # 예약/외부 링크 탭 (MVP)
   │   └─ AnalysisView.swift            # 분석 탭 (MVP)
   │
   ├─ Preview Content/
   │   └─ Preview Assets                # SwiftUI 프리뷰용 더미 데이터
   │
   ├─ Assets.xcassets                   # 색상, 아이콘, 앱 심볼
   └─ Config/                           # 빌드/환경 관련 추가 설정
```

---

## ⚙️ 실행 방법

### 1. 레포 클론

```bash
git clone https://github.com/<your-id>/DipAir.git
cd DipAir
```


### 2. Amadeus API 키 발급

- Amadeus for Developers  계정 생성

- Test 환경 애플리케이션 생성

- 대시보드에서 아래 값 확인

- API key / API secret

### 3. APIConfiguration.swift 생성

- 레포에는 보안상 포함되어 있지 않으므로, 로컬에서 직접 파일을 만들어야 합니다.

### 4. Xcode에서 실행

- DipAir.xcodeproj 열기

- 타깃(Target)을 DipAir로 선택

- 시뮬레이터(예: iPhone 16 Pro) 선택

- ⌘ + R 로 빌드 & 실행

---

## 🚧 현재 한계 & TODO
### Amadeus Test API 특성상

- 특정 날짜/출발지 조합에서는 500 (SYSTEM ERROR) / 429 (Too many requests) 발생
- 이런 경우, 콘솔에 상세 에러로그 출력 후 데모/더미 데이터 출력을 동작하도록 구현하였습니다.

