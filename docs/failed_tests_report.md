# Звіт про провалені тести

**Загальна кількість провалених тестів:** 192 -> **45 залишилось** (147 виправлено)

**Згенеровано з:** flutter test

**Останнє оновлення:** Виправлено 9 тестових файлів

---

## Прогрес виправлення

| Файл | Статус | Виправлено |
|------|--------|------------|
| aquarium_remote_ds_test.dart | ✅ Виправлено | 11 тестів |
| app_test.dart | ✅ Виправлено | 17 тестів |
| app_router_test.dart | ✅ Виправлено | 17 тестів |
| navigation_flow_test.dart | ✅ Виправлено | 11 тестів |
| register_screen_test.dart | ✅ Виправлено | 20 тестів |
| login_screen_test.dart | ✅ Виправлено | 18 тестів |
| my_aquarium_screen_test.dart | ✅ Виправлено | 18 тестів |
| home_screen_test.dart | ✅ Виправлено | 17 тестів |
| onboarding_screen_test.dart | ✅ Виправлено | 18 тестів |
| **Всього виправлено** | | **147 тестів** |

---

## Підсумок по групах

| Група | Провалено | Найбільш проблемні файли |
|-------|-----------|--------------------------|
| presentation | 35 ~~154~~ | ~~register_screen_test.dart (20)~~, ~~login_screen_test.dart (18)~~, ~~my_aquarium_screen_test.dart (18)~~, ~~onboarding_screen_test.dart (18)~~, ~~home_screen_test.dart (17)~~, ~~app_router_test.dart (17)~~, ~~navigation_flow_test.dart (11)~~ |
| app_test.dart | ~~17~~ ✅ | ~~app_test.dart (17)~~ |
| data | 2 ~~13~~ | ~~aquarium_remote_ds_test.dart (11)~~, auth_repository_impl_test.dart (2) |
| services | 5 | sync_service_test.dart (4), sync_trigger_service_test.dart (1) |
| widget_test.dart | 2 | widget_test.dart (2) |
| domain | 1 | ai_scan_limit_usecase_test.dart (1) |

---

## Детальний розподіл по файлах

### Presentation (35 провалено, 119 виправлено)

| Файл | Шлях | Провалено |
|------|------|-----------|
| ~~register_screen_test.dart~~ | `test/presentation/screens/auth/` | ~~20~~ ✅ |
| ~~login_screen_test.dart~~ | `test/presentation/screens/auth/` | ~~18~~ ✅ |
| ~~my_aquarium_screen_test.dart~~ | `test/presentation/screens/aquarium/` | ~~18~~ ✅ |
| ~~onboarding_screen_test.dart~~ | `test/presentation/screens/onboarding/` | ~~18~~ ✅ |
| ~~home_screen_test.dart~~ | `test/presentation/screens/home/` | ~~17~~ ✅ |
| ~~app_router_test.dart~~ | `test/presentation/router/` | ~~17~~ ✅ |
| ~~navigation_flow_test.dart~~ | `test/presentation/router/` | ~~11~~ ✅ |
| achievements_gallery_golden_test.dart | `test/presentation/widgets/profile/` | 8 |
| auth_provider_test.dart | `test/presentation/providers/` | 6 |
| streak_section_golden_test.dart | `test/presentation/widgets/profile/` | 5 |
| achievements_gallery_test.dart | `test/presentation/widgets/profile/` | 4 |
| achievement_unlock_overlay_test.dart | `test/presentation/widgets/gamification/` | 3 |
| today_view_test.dart | `test/presentation/screens/home/` | 2 |
| day_detail_sheet_test.dart | `test/presentation/widgets/calendar/` | 2 |
| my_aquarium_section_test.dart | `test/presentation/widgets/profile/` | 2 |
| join_family_screen_test.dart | `test/presentation/screens/family/` | 1 |
| family_screen_test.dart | `test/presentation/screens/settings/` | 1 |
| statistics_section_test.dart | `test/presentation/widgets/profile/` | 1 |

### Data (2 провалено, 11 виправлено)

| Файл | Шлях | Провалено |
|------|------|-----------|
| ~~aquarium_remote_ds_test.dart~~ | `test/data/datasources/remote/` | ~~11~~ ✅ |
| auth_repository_impl_test.dart | `test/data/repositories/` | 2 |

### Services (5 провалено)

| Файл | Шлях | Провалено |
|------|------|-----------|
| sync_service_test.dart | `test/services/sync/` | 4 |
| sync_trigger_service_test.dart | `test/services/sync/` | 1 |

### Інші (3 провалено, 17 виправлено)

| Файл | Шлях | Провалено |
|------|------|-----------|
| ~~app_test.dart~~ | `test/` | ~~17~~ ✅ |
| widget_test.dart | `test/` | 2 |
| ai_scan_limit_usecase_test.dart | `test/domain/usecases/` | 1 |

---

## Детальний список провалених тестів

### app_test.dart ~~(17 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/app_test.dart`*

- [x] FishFeedApp renders without errors
- [x] FishFeedApp uses MaterialApp.router
- [x] FishFeedApp has correct app title
- [x] FishFeedApp debug banner is hidden
- [x] FishFeedApp has light and dark themes configured
- [x] FishFeedApp uses ThemeMode.system
- [x] FishFeedApp displays auth screen initially (user not logged in)
- [x] FishFeedApp applies AppTheme.lightTheme correctly
- [x] FishFeedApp applies AppTheme.darkTheme correctly
- [x] AppRouter integration GoRouter is properly connected
- [x] AppRouter integration initial route redirects to auth for unauthenticated user

---

### Data (13 провалено)

#### aquarium_remote_ds_test.dart ~~(11 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/data/datasources/remote/aquarium_remote_ds_test.dart`*

- [x] AquariumRemoteDataSourceImpl createAquarium should call POST /aquariums with name only
- [x] AquariumRemoteDataSourceImpl createAquarium should call POST /aquariums with all parameters
- [x] AquariumRemoteDataSourceImpl createAquarium should return AquariumDto on success
- [x] AquariumRemoteDataSourceImpl getAquariums should call GET /aquariums
- [x] AquariumRemoteDataSourceImpl getAquariums should return list of AquariumDto on success
- [x] AquariumRemoteDataSourceImpl getAquariumById should call GET /aquariums/{id}
- [x] AquariumRemoteDataSourceImpl getAquariumById should return AquariumDto on success
- [x] AquariumRemoteDataSourceImpl updateAquarium should call PUT /aquariums/{id} with name
- [x] AquariumRemoteDataSourceImpl updateAquarium should call PUT with multiple parameters
- [x] AquariumRemoteDataSourceImpl updateAquarium should return updated AquariumDto on success
- [x] AquariumRemoteDataSourceImpl updateAquarium should throw DioException on error

#### auth_repository_impl_test.dart (2 провалено)
*Шлях: `test/data/repositories/auth_repository_impl_test.dart`*

- [ ] logout should clear local data and return unit
- [ ] logout should still clear local data when server logout fails

---

### Domain (1 провалено)

#### ai_scan_limit_usecase_test.dart (1 провалено)
*Шлях: `test/domain/usecases/ai_scan_limit_usecase_test.dart`*

- [ ] decrementScanCount should return CacheFailure when update fails

---

### Presentation (35 провалено, 119 виправлено)

#### auth_provider_test.dart (6 провалено)
*Шлях: `test/presentation/providers/auth_provider_test.dart`*

- [ ] Riverpod providers authNotifierProvider should create AuthNotifier
- [ ] Riverpod providers authStateProvider should return current state
- [ ] Riverpod providers currentUserProvider should return null when not authenticated
- [ ] Riverpod providers isAuthenticatedProvider should return false initially
- [ ] AuthStateListenable should provide isLoggedIn based on auth state
- [ ] AuthStateListenable should notify listeners on state change

#### app_router_test.dart ~~(17 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/router/app_router_test.dart`*

- [x] AppRouter createRouter redirects to /auth on initial load for unauthenticated user
- [x] AppRouter redirect logic unauthenticated user redirects to /auth from home
- [x] AppRouter redirect logic unauthenticated user can stay on /auth
- [x] AppRouter redirect logic unauthenticated user redirects to /auth from /calendar
- [x] AppRouter redirect logic unauthenticated user redirects to /auth from /profile
- [x] AppRouter redirect logic unauthenticated user redirects to /auth from /settings
- [x] AppRouter redirect logic authenticated user without onboarding redirects to /onboarding from home
- [x] AppRouter redirect logic authenticated user with completed onboarding can access home (/)
- [x] AppRouter redirect logic authenticated user with completed onboarding redirects to / from /auth
- [x] AppRouter redirect logic authenticated user with completed onboarding redirects to / from /onboarding
- [x] AppRouter redirect logic authenticated user with completed onboarding can access /calendar
- [x] AppRouter redirect logic authenticated user with completed onboarding can access /profile
- [x] AppRouter redirect logic authenticated user with completed onboarding can access /settings
- [x] AppRouter redirect logic authenticated user with completed onboarding can access /aquarium
- [x] AppRouter redirect logic authenticated user with completed onboarding can access /aquarium/fish/:fishId/edit with parameter
- [x] AppRouter redirect logic reactive updates on auth state change redirects to / after login + onboarding
- [x] AppRouter redirect logic reactive updates on auth state change redirects to /auth after logout

#### navigation_flow_test.dart ~~(11 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/router/navigation_flow_test.dart`*

- [x] Navigation Flow Integration Tests new user flow new user is redirected to onboarding after login
- [x] Navigation Flow Integration Tests new user flow new user is redirected to home after completing onboarding
- [x] Navigation Flow Integration Tests existing user flow existing user is redirected to home after login
- [x] Navigation Flow Integration Tests unauthenticated redirect unauthenticated user is redirected to login from home
- [x] Navigation Flow Integration Tests unauthenticated redirect unauthenticated user is redirected to login from protected routes
- [x] Navigation Flow Integration Tests authenticated redirect from auth routes authenticated user with onboarding is redirected from auth to home
- [x] Navigation Flow Integration Tests authenticated redirect from auth routes authenticated user with onboarding is redirected from register to home
- [x] Navigation Flow Integration Tests logout flow user is redirected to login after logout
- [x] Navigation Flow Integration Tests logout flow protected routes are not accessible after logout
- [x] Navigation Flow Integration Tests navigation between auth screens can navigate from login to register
- [x] Navigation Flow Integration Tests onboarding completion user stays on onboarding until completion then redirects to home

#### my_aquarium_screen_test.dart ~~(18 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/screens/aquarium/my_aquarium_screen_test.dart`*

- [x] MyAquariumScreen loading state renders without errors during initial load
- [x] MyAquariumScreen empty state shows empty state when no fish
- [x] MyAquariumScreen empty state empty state CTA shows bottom sheet
- [x] MyAquariumScreen fish list displays fish list correctly
- [x] MyAquariumScreen fish list displays fish icon for each item
- [x] MyAquariumScreen FAB FAB is present
- [x] MyAquariumScreen FAB FAB shows bottom sheet with options
- [x] MyAquariumScreen popup menu shows popup menu button for each fish
- [x] MyAquariumScreen popup menu popup menu shows Edit and Delete options
- [x] MyAquariumScreen popup menu tapping Delete shows confirmation dialog
- [x] MyAquariumScreen popup menu confirmation dialog Cancel dismisses dialog
- [x] MyAquariumScreen popup menu confirmation dialog Delete removes fish
- [x] MyAquariumScreen popup menu shows SnackBar after successful deletion
- [x] MyAquariumScreen error state shows error state on load failure
- [x] MyAquariumScreen error state retry button is tappable
- [x] MyAquariumScreen pull to refresh can pull to refresh fish list

#### login_screen_test.dart ~~(18 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/screens/auth/login_screen_test.dart`*

- [x] LoginScreen UI rendering renders all required widgets
- [x] LoginScreen UI rendering password field has visibility toggle
- [x] LoginScreen form validation shows error for empty email
- [x] LoginScreen form validation shows error for invalid email format
- [x] LoginScreen form validation shows error for empty password
- [x] LoginScreen form validation shows error for weak password
- [x] LoginScreen form validation validates email with valid format
- [x] LoginScreen login functionality calls login with correct credentials
- [x] LoginScreen login functionality shows loading indicator during login
- [x] LoginScreen login functionality shows snackbar on login error
- [x] LoginScreen Google OAuth calls Google login when button is pressed
- [x] LoginScreen Google OAuth shows snackbar on Google login error
- [x] LoginScreen password visibility toggle toggles password visibility icon on tap
- [x] LoginScreen email format validation accepts valid email formats
- [x] LoginScreen email format validation rejects invalid email formats
- [x] LoginScreen password format validation accepts valid password formats
- [x] LoginScreen password format validation rejects invalid password formats
- [x] LoginScreen button states login button is disabled during loading

#### register_screen_test.dart ~~(20 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/screens/auth/register_screen_test.dart`*

- [x] RegisterScreen UI rendering renders all required widgets
- [x] RegisterScreen UI rendering password fields have visibility toggles
- [x] RegisterScreen password strength indicator shows no indicator for empty password
- [x] RegisterScreen password strength indicator shows weak indicator for short password
- [x] RegisterScreen password strength indicator shows medium indicator for moderate password
- [x] RegisterScreen password strength indicator shows strong indicator for strong password
- [x] RegisterScreen form validation shows error for empty email
- [x] RegisterScreen form validation shows error for invalid email format
- [x] RegisterScreen form validation shows error for weak password
- [x] RegisterScreen form validation shows error for mismatched passwords
- [x] RegisterScreen form validation shows error when ToS checkbox is not checked
- [x] RegisterScreen ToS checkbox checkbox toggles on tap
- [x] RegisterScreen ToS checkbox checkbox toggles on tap again
- [x] RegisterScreen ToS checkbox ToS error clears when checkbox is checked
- [x] RegisterScreen registration functionality calls register with correct credentials
- [x] RegisterScreen registration functionality shows loading indicator during registration
- [x] RegisterScreen registration functionality shows snackbar on registration error
- [x] RegisterScreen password visibility toggle toggles password visibility icon on tap
- [x] RegisterScreen password visibility toggle confirm password visibility is independent
- [x] RegisterScreen button states create account button is disabled during loading

#### join_family_screen_test.dart (1 провалено)
*Шлях: `test/presentation/screens/family/join_family_screen_test.dart`*

- [ ] JoinFamilyScreen error state shows login button for auth error

#### home_screen_test.dart ~~(17 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/screens/home/home_screen_test.dart`*

- [x] HomeScreen AppBar displays greeting with user display name
- [x] HomeScreen AppBar displays greeting with email when no display name
- [x] HomeScreen AppBar displays streak badge placeholder
- [x] HomeScreen BottomNavigationBar displays 3 navigation destinations
- [x] HomeScreen BottomNavigationBar displays correct labels for tabs
- [x] HomeScreen BottomNavigationBar displays correct icons for tabs
- [x] HomeScreen BottomNavigationBar Home tab is selected by default
- [x] HomeScreen BottomNavigationBar can navigate to Calendar tab
- [x] HomeScreen BottomNavigationBar can navigate to Profile tab
- [x] HomeScreen BottomNavigationBar tab navigation preserves state with IndexedStack
- [x] HomeScreen FloatingActionButton displays FAB with add icon
- [x] HomeScreen FloatingActionButton FAB navigates to AI camera when pressed
- [x] HomeScreen Tab placeholder content TodayView shows correct empty state
- [x] HomeScreen Tab placeholder content TodayView shows feedings when available
- [x] HomeScreen Tab placeholder content Calendar tab shows CalendarScreen
- [x] HomeScreen Tab placeholder content Profile tab shows ProfileScreen with user info
- [x] HomeScreen Greeting time-based logic greeting contains user name

#### today_view_test.dart (2 провалено)
*Шлях: `test/presentation/screens/home/today_view_test.dart`*

- [ ] TodayView Empty State displays empty state when no feedings scheduled
- [ ] TodayView Aquarium Grouping shows empty state message for aquarium with no feedings

#### onboarding_screen_test.dart ~~(18 провалено)~~ ✅ ВИПРАВЛЕНО
*Шлях: `test/presentation/screens/onboarding/onboarding_screen_test.dart`*

- [x] OnboardingScreen should display quantity step when navigated via notifier
- [x] OnboardingScreen should display Back button on second step
- [x] OnboardingScreen should navigate back when Back pressed
- [x] OnboardingScreen should show Done on last step in add mode
- [x] OnboardingScreen should show Get Started on last step in full onboarding
- [x] SpeciesSelectionStep should limit selection to 3 species
- [x] QuantityStep should display selected species
- [x] QuantityStep should show quantity counters
- [x] QuantityStep should increment quantity on + tap
- [x] QuantityStep should decrement quantity on - tap
- [x] QuantityStep should disable - button when quantity is 1
- [x] QuantityStep should disable + button when quantity is 50
- [x] SchedulePreviewStep should display schedule preview header
- [x] SchedulePreviewStep should have generated schedule when on step
- [x] SchedulePreviewStep should display summary card with fish count
- [x] SchedulePreviewStep should display summary card with feedings per day
- [x] SchedulePreviewStep should display edit icons for feeding times
- [x] SchedulePreviewStep should display feeding times
- [x] SchedulePreviewStep should display food type and portion

#### family_screen_test.dart (1 провалено)
*Шлях: `test/presentation/screens/settings/family_screen_test.dart`*

- [ ] FamilyScreen - Tier Limits shows upgrade prompt when free tier limit reached

#### day_detail_sheet_test.dart (2 провалено)
*Шлях: `test/presentation/widgets/calendar/day_detail_sheet_test.dart`*

- [ ] DayDetailSheet Empty State displays empty state when no feedings
- [ ] DayDetailSheet Empty State displays "No feedings scheduled" in header for empty state

#### achievement_unlock_overlay_test.dart (3 провалено)
*Шлях: `test/presentation/widgets/gamification/achievement_unlock_overlay_test.dart`*

- [ ] AchievementUnlockQueue should display first achievement initially
- [ ] AchievementUnlockQueue should show next achievement after dismiss
- [ ] AchievementUnlockQueue should call onAllDismissed after last achievement

#### achievements_gallery_golden_test.dart (8 провалено)
*Шлях: `test/presentation/widgets/profile/achievements_gallery_golden_test.dart`*

- [ ] AchievementsGallery Golden Tests all locked achievements
- [ ] AchievementsGallery Golden Tests first achievement unlocked
- [ ] AchievementsGallery Golden Tests three achievements unlocked
- [ ] AchievementsGallery Golden Tests all achievements unlocked
- [ ] AchievementsGallery Golden Tests loading state
- [ ] AchievementsGallery Golden Tests error state
- [ ] AchievementsGallery Golden Tests dark mode - three unlocked
- [ ] AchievementsGallery Golden Tests with progress on locked achievements

#### achievements_gallery_test.dart (4 провалено)
*Шлях: `test/presentation/widgets/profile/achievements_gallery_test.dart`*

- [ ] AchievementsGallery Display displays unlocked achievement title
- [ ] AchievementsGallery Detail Modal opens modal when tile is tapped
- [ ] AchievementsGallery Detail Modal modal shows description
- [ ] AchievementsGallery Locked vs Unlocked Visual States unlocked achievement has colored background

#### my_aquarium_section_test.dart (2 провалено)
*Шлях: `test/presentation/widgets/profile/my_aquarium_section_test.dart`*

- [ ] MyAquariumSection Empty State "Add your first fish" navigates to AI Camera
- [ ] MyAquariumSection Action Buttons Add Fish button navigates to AI Camera

#### statistics_section_test.dart (1 провалено)
*Шлях: `test/presentation/widgets/profile/statistics_section_test.dart`*

- [ ] StatisticsSection Display displays on-time percentage

#### streak_section_golden_test.dart (5 провалено)
*Шлях: `test/presentation/widgets/profile/streak_section_golden_test.dart`*

- [ ] StreakSection Golden Tests streak 0 - new user
- [ ] StreakSection Golden Tests streak 7 - first milestone
- [ ] StreakSection Golden Tests streak 30 - one month milestone
- [ ] StreakSection Golden Tests streak 100 - epic milestone
- [ ] StreakSection Golden Tests dark mode - streak 15

---

### Services (5 провалено)

#### sync_service_test.dart (4 провалено)
*Шлях: `test/services/sync/sync_service_test.dart`*

- [ ] SyncService connectivity should detect online status on startListening
- [ ] SyncService syncAll should update state to success after successful sync
- [ ] SyncService state stream should emit state changes
- [ ] SyncService dispose should clean up resources on dispose

#### sync_trigger_service_test.dart (1 провалено)
*Шлях: `test/services/sync/sync_trigger_service_test.dart`*

- [ ] Nothing to Sync should not trigger sync when nothing to sync

---

### widget_test.dart (2 провалено)
*Шлях: `test/widget_test.dart`*

- [ ] App renders correctly
- [ ] App renders correctly
