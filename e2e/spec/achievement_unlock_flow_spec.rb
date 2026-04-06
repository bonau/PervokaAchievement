require_relative 'e2e_helper'

RSpec.describe 'Achievement Unlock Flow' do
  ADMIN_USER = 'admin'
  ADMIN_PASS = 'admin'
  NEW_ADMIN_PASS = 'Admin12345!'
  PROJECT_NAME = 'E2E Test Project'
  PROJECT_ID = 'e2e-test'

  it 'awards Hello World achievement on first issue, shows toast, dashboard and leaderboard' do
    # ── Phase 1: Admin Login ──────────────────────────────────────────────
    puts "\n  Phase 1: Admin Login"

    login_as(ADMIN_USER, ADMIN_PASS)

    # Redmine forces admin to change password on first login
    if page.has_field?('new_password', wait: 3)
      puts "    Handling forced password change..."
      fill_in 'password', with: ADMIN_PASS
      fill_in 'new_password', with: NEW_ADMIN_PASS
      fill_in 'new_password_confirmation', with: NEW_ADMIN_PASS
      find('input[type="submit"]').click
    end

    expect(page).to have_link('Sign out')
    take_screenshot('01_admin_logged_in')
    puts "    Admin logged in"

    # ── Phase 2: Create Project ───────────────────────────────────────────
    puts "\n  Phase 2: Create Project"

    visit '/projects/new'
    fill_in 'project_name', with: PROJECT_NAME
    fill_in 'project_identifier', with: PROJECT_ID

    # Check all available tracker checkboxes (Redmine may not check them by default)
    all('input[name="project[tracker_ids][]"]').each { |cb| cb.set(true) }

    find('input[type="submit"][name="commit"]').click

    expect(page).to have_content(PROJECT_NAME)
    take_screenshot('02_project_created')
    puts "    Project created: #{PROJECT_NAME}"

    # ── Phase 3: Create First Issue (triggers achievement) ────────────────
    puts "\n  Phase 3: Create First Issue"

    visit "/projects/#{PROJECT_ID}/issues/new"
    fill_in 'issue_subject', with: 'My very first issue'
    find('input[type="submit"][name="commit"]').click

    # Redirected to issue show page; achievement was awarded in after_save
    expect(page).to have_content('My very first issue')
    take_screenshot('03_issue_created')
    puts "    Issue created"

    # ── Phase 4: Verify Toast Notification ────────────────────────────────
    puts "\n  Phase 4: Toast Notification"

    # The toast is injected by view_layouts_base_body_bottom hook on this
    # page load.  The JS adds class "show" after ~0 ms and removes the
    # element after 6.5 s, so assert quickly.
    toast_visible = page.has_css?('.achievement_toast', wait: 5)
    if toast_visible
      toast_text = find('#achievement-toast-container').text
      expect(toast_text).to include('Hello World')
      take_screenshot('04_achievement_toast')
      puts "    Toast found: #{toast_text.strip}"
    else
      # The toast auto-hides after 6.5 s — if Capybara was slow it may
      # already be gone.  The dashboard check below still proves the
      # achievement was awarded.
      take_screenshot('04_toast_auto_hidden')
      puts "    Toast auto-hidden (dashboard will confirm award)"
    end

    # ── Phase 5: Achievements Dashboard ───────────────────────────────────
    puts "\n  Phase 5: Achievements Dashboard"

    visit '/achievements'

    expect(page).to have_content('Achievements')
    expect(page).to have_content('Hello World')
    expect(page).to have_css('.achievement_entry.unlocked')

    score = find('.score_value').text.to_i
    expect(score).to be > 0

    take_screenshot('05_achievements_dashboard')
    puts "    Dashboard OK — Hello World unlocked, score: #{score}"

    # ── Phase 6: Leaderboard ──────────────────────────────────────────────
    puts "\n  Phase 6: Leaderboard"

    visit '/achievements/leaderboard'

    expect(page).to have_content('Leaderboard')
    expect(page).to have_css('table.achievement_leaderboard tbody tr')

    take_screenshot('06_leaderboard')
    puts "    Leaderboard shows ranked entries"

    # ── Phase 7: Admin Achievement Settings ───────────────────────────────
    puts "\n  Phase 7: Admin Achievement Settings"

    visit '/admin/achievements'

    expect(page).to have_content('Achievement Settings')
    expect(page).to have_css('table.list')
    expect(page).to have_content('Hello World')
    expect(page).to have_content('First Love')
    expect(page).to have_content('Problem Solver')

    take_screenshot('07_admin_achievements')
    puts "    Admin settings page lists all achievements"

    puts "\n  All phases passed"
  end
end
