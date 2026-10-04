/// Central game configuration constants.
/// Tweak balance from here without touching logic.
class GameConfig {
  // Starting state
  static const int startingCredits = 5000;
  static const int startingCreditScore = 1000;
  static const int maxCreditScore = 10000;

  // Travel
  static const int defaultTravelCost = 50;

  // Banking
  static const double loanInterestRate = 0.10;
  static const int loanDeadlineTurns = 5;
  static const int loanGracePeriodTurns = 3;
  static const double loanOverdueInterestRate = 0.10; // per turn
  static const int creditOnTimeRepay = 200;
  static const int creditLateRepay = -400;
  static const int maxLoanAmount = 10000;

  // Insurance
  static const double insuranceBasicRate = 0.03;
  static const double insuranceStandardRate = 0.05;
  static const double insurancePremiumRate = 0.08;
  static const double insuranceBasicCargoCoverage = 0.0;
  static const double insuranceStandardCargoCoverage = 0.5;
  static const double insurancePremiumCargoCoverage = 1.0;

  // Fleet
  static const int maxShipsOwned = 15;
  static const int maxShipsEquipped = 10;
  static const int maxShipsFlying = 10;
  static const int maxShipsStored = 5;
  static const int baseCargoCapacity = 20;
  static const int cargoUpgradePerLevel = 5;
  static const int weaponUpgradePerLevel = 1;
  static const double shipSellValueRatio = 0.8;
  static const double shipRepairCostRatio = 0.10;

  // Prices
  static const double priceVolatility = 0.20; // ±20%
  static const int priceRerollInterval = 3; // every 3 turns minimum

  // Encounters
  static const double encounterChance = 0.25; // 25% on travel
  static const double pirateEncounterRatio = 0.50;
  static const double policeEncounterRatio = 0.25;
  static const double traderEncounterRatio = 0.25;

  // Missions
  static const int missionDeadlineTurns = 5;
  static const int missionMinReward = 500;
  static const int missionMaxReward = 2000;
  static const int missionCreditBoost = 100;

  // Bounty (from attacking traders)
  static const int bountyPerAttack = 50;
  static const int maxBounty = 1000;
  static const int bountyClearCost = 5000;

  // Alerts
  static const int alertAdvanceTurns = 2; // alert 2 turns before due

  // Save
  static const int maxSaveSlots = 5;
  static const int saveVersion = 1;

  // Game loop
  static const String startingPlanetId = 'terra';
  static const int startingTurn = 0;
}
