# Story: US-07 Choose the look I like (Done)
Feature: Choose the look I like
  As a car owner
  I want to switch between the Simple, Racing, Power and Retro looks
  So that the app suits how I use it

  Background:
    Given the app is using the Simple look

  Scenario: Switching the look applies to every screen
    Given the car owner is connected to their car
    When they switch the look to Racing in settings
    Then all five screens use the Racing look
    And the app stays connected to the car

  Scenario: The header switch steps through the looks
    Given the car owner is on the Live screen
    When they tap the look switch in the header four times
    Then the app shows the Racing look, then the Power look, then the Retro look, then the Simple look again

  Scenario: The chosen look is kept after closing the app
    Given the car owner has chosen the Racing look
    When they close and reopen the app
    Then the app uses the Racing look

  Scenario Outline: Every look is readable in light and dark mode
    Given the app is using the <look> look
    And the phone is in <appearance> mode
    When the screens are checked for contrast
    Then every screen passes the contrast check

    Examples:
      | look   | appearance |
      | Simple | light      |
      | Simple | dark       |
      | Racing | light      |
      | Racing | dark       |
      | Power  | light      |
      | Power  | dark       |
      | Retro  | light      |
      | Retro  | dark       |
