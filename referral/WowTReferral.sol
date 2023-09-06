// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { WowTPoints, AccessControlUpgradeable, PausableUpgradeable } from './WowTPoints.sol';

/**
 * @title WowTReferral
 * @dev A smart contract that manages referral points for the WowTPoints token.
 * Users can earn referral points by referring new users to the platform. Referrals can earn additional
 * points by referring their own network of users.
 */
contract WowTReferral is PausableUpgradeable, AccessControlUpgradeable {
  /**
   * @dev A struct to represent a referral user.
   * @param referralAddress The Ethereum address of the referred user.
   * @param referralExists A boolean indicating whether the referral exists.
   */
  struct ReferralUser {
    address referralAddress;
    bool referralExists;
    address installAddress;
    uint256 timestamp;
  }

  /**
   * @dev A mapping to store referral data for each user.
   */
  mapping(address => ReferralUser) private referrer;

  mapping(address => address[]) private referrals;

  address[] public allAddresses; // Array to store all addresses that have referral

  address public pointsContract; // The address of the WowTPoints contract.

  /// @dev The WowTPoints contract to which referral points are added.
  WowTPoints private points;

  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Admin role for authorization

  /// @dev Modifier to restrict function access to only those with the admin role.
  modifier adminOnly() {
    require(hasRole(ADMIN_ROLE, _msgSender()), 'Must have referral admin role');
    _;
  }

  /**
   * @dev Initializes the contract and sets the WowTPoints contract.
   * @param _pointsContract The address of the WowTPoints contract.
   */
  function initialize(address _pointsContract) external initializer {
    __Pausable_init();
    _grantRole(ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    pointsContract = _pointsContract;
    points = WowTPoints(_pointsContract);
  }

  /**
   * @dev Adds referral points to a user's account and records the referral relationship between the installer and the referrer.
   * @param _installAddress The address of the user who installed the application and triggered the referral.
   * @param _referralAddress The address of the user who referred the installer to the application.
   */
  function addReferralPoints(
    address _installAddress,
    address _referralAddress
  ) public adminOnly whenNotPaused {
    require(!referrer[_installAddress].referralExists, 'Already have referrar');
    require(_installAddress != _referralAddress, "Can't refer yourself");
    require(
      referrer[_referralAddress].referralAddress != _installAddress,
      'You are referer'
    );
    points.addPoints(_referralAddress, 'levelOne');
    referrer[_installAddress].referralAddress = _referralAddress;
    referrer[_installAddress].referralExists = true;
    referrer[_installAddress].installAddress = _installAddress;
    referrer[_installAddress].timestamp = block.timestamp; // Store the timestamp
    // Check for referrals and update allAddresses array
    if (referrals[_installAddress].length == 0) {
      allAddresses.push(_installAddress);
    }
    referrals[_referralAddress].push(_installAddress);
    points.addReferralPoints(
      _referralAddress,
      points.getPointsValue('levelOne')
    );
    if (referrer[_referralAddress].referralExists) {
      address secondLevelAddress = referrer[_referralAddress].referralAddress;
      points.addPoints(secondLevelAddress, 'levelTwo');
      points.addReferralPoints(
        secondLevelAddress,
        points.getPointsValue('levelTwo')
      );
    }
  }

  function getReferralsTimeBased(
    uint256 startTime,
    uint256 endTime
  ) public view returns (ReferralUser[] memory) {
    require(startTime <= endTime, 'Invalid time range');

    ReferralUser[] memory resultReferrals = new ReferralUser[](
      allAddresses.length
    );
    uint256 resultCount;

    for (uint256 i = 0; i < allAddresses.length; i++) {
      address referredAddress = allAddresses[i];
      ReferralUser memory referralData = referrer[referredAddress];

      if (
        referralData.referralExists &&
        referralData.timestamp >= startTime &&
        referralData.timestamp <= endTime
      ) {
        address installAddress = referralData.referralAddress;

        resultReferrals[resultCount] = ReferralUser(
          referredAddress,
          true,
          installAddress,
          referralData.timestamp
        );
        resultCount++;
      }
    }

    ReferralUser[] memory finalResult = new ReferralUser[](resultCount);
    for (uint256 i = 0; i < resultCount; i++) {
      finalResult[i] = resultReferrals[i];
    }

    return finalResult;
  }

  /**
   * @dev Gets the referral data for a given user.
   * @param _account The Ethereum address of the user.
   * @return ReferralUser The referral data for the user.
   */
  function getReferrer(
    address _account
  ) public view returns (ReferralUser memory) {
    return referrer[_account];
  }

  /**
   * @dev Gets the list of referrals for a given user.
   * @param _account The Ethereum address of the user.
   * @return address[] The list of referrals for the user.
   */
  function getReferrals(
    address _account
  ) public view returns (address[] memory) {
    return referrals[_account];
  }

  function setPointsContractAddress(
    address _pointsContract
  ) external adminOnly whenNotPaused {
    pointsContract = _pointsContract;
    points = WowTPoints(pointsContract);
  }

  function pause() public adminOnly {
    _pause();
  }

  function unpause() public adminOnly {
    _unpause();
  }
}
