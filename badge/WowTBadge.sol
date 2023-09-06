// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { WowTPoints, AccessControlUpgradeable, PausableUpgradeable } from './WowTPoints.sol';

/**
 * @title WowTBadge
 * @dev The WowTBadge contract allows users to earn and display badges for their performance on the WowTPoints leaderboard.
 */
contract WowTBadge is AccessControlUpgradeable, PausableUpgradeable {
  /**
   * @dev A struct to represent a badge earned by a user.
   * @param yearWeek The year and week number (in YYYY-WW format) during which the user earned the badge.
   * @param image The URI of the image associated with the badge.
   */
  struct Badge {
    uint256 timestamp;
    address account;
    string yearWeek;
    string image;
  }

  string public imageUri; // The URI of the default badge image.
  address public pointsContract; // The address of the WowTPoints contract.
  WowTPoints private points; // The WowTPoints contract instance.

  mapping(address => Badge[]) private badgesByAddress; // A mapping to store badges earned by each user.
  address[] private allAddresses; // Array to store all addresses that have earned badges

  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Admin role for authorization

  /// @dev Modifier to restrict function access to only those with the admin role.
  modifier adminOnly() {
    require(hasRole(ADMIN_ROLE, _msgSender()), 'Must have badge admin role');
    _;
  }

  /**
   * @dev Initializes the contract and sets the URI for the badge images.
   * @param _imageUri The URI for the badge images.
   * @param _pointsContract The address of the WowTPoints contract.
   */
  function initialize(
    string memory _imageUri,
    address _pointsContract
  ) external initializer {
    __Pausable_init();
    _grantRole(ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    imageUri = _imageUri;
    pointsContract = _pointsContract;
    points = WowTPoints(pointsContract);
  }

  /**
   * @dev Adds a badge to the list of badges earned by the user who is at the top of the leaderboard for the given week.
   * @param yearWeek The year and week number (in YYYY-WW format) during which the user earned the badge.
   */
  // function updateBadgeForWeek(
  //   string memory yearWeek
  // ) external adminOnly whenNotPaused {
  //   // WowTPoints points = WowTPoints(pointsContract);
  //   address leaderBoardAddress = points.getTopRankedAddress();
  //   Badge memory newBadge = Badge(block.timestamp, leaderBoardAddress, yearWeek, imageUri);
  //   badges[leaderBoardAddress].push(newBadge);
  // }

  function updateBadgeForWeek(
    string memory yearWeek
  ) external adminOnly whenNotPaused {
    address leaderBoardAddress = points.getTopRankedAddress();
    Badge memory newBadge = Badge(
      block.timestamp,
      leaderBoardAddress,
      yearWeek,
      imageUri
    );

    if (badgesByAddress[leaderBoardAddress].length == 0) {
      allAddresses.push(leaderBoardAddress);
    }

    badgesByAddress[leaderBoardAddress].push(newBadge);
  }

  /**
   * @dev Sets the URI for the badge images.
   * @param _imageUrl The new URI for the default badge image.
   */
  function setImageUri(
    string memory _imageUrl
  ) external adminOnly whenNotPaused {
    imageUri = _imageUrl;
  }

  function setPointsContractAddress(
    address _pointsContract
  ) external adminOnly whenNotPaused {
    pointsContract = _pointsContract;
    points = WowTPoints(pointsContract);
  }

  /**
   * @dev Gets the list of badges earned by a given user.
   * @param account The address of the user whose badges to retrieve.
   * @return An array of Badge structs representing the user's badges.
   */
  // function getBadges(address account) public view returns (Badge[] memory) {
  //   return badges[account];
  // }

  function getBadges(address account) public view returns (Badge[] memory) {
    return badgesByAddress[account];
  }

  function getBadgesByTimeBased(
    uint256 startTime,
    uint256 endTime
  ) public view returns (Badge[] memory) {
    uint256 resultCount;

    for (uint256 i = 0; i < allAddresses.length; i++) {
      address account = allAddresses[i];
      Badge[] storage userBadges = badgesByAddress[account];
      uint256 badgesCount = userBadges.length;

      for (uint256 j = 0; j < badgesCount; j++) {
        Badge storage badge = userBadges[j];
        if (badge.timestamp >= startTime && badge.timestamp <= endTime) {
          resultCount++;
        }
      }
    }

    Badge[] memory resultBadges = new Badge[](resultCount);
    uint256 resultIndex;

    for (uint256 i = 0; i < allAddresses.length; i++) {
      address account = allAddresses[i];
      Badge[] storage userBadges = badgesByAddress[account];
      uint256 badgesCount = userBadges.length;

      for (uint256 j = 0; j < badgesCount; j++) {
        Badge storage badge = userBadges[j];
        if (badge.timestamp >= startTime && badge.timestamp <= endTime) {
          resultBadges[resultIndex] = badge;
          resultIndex++;
        }
      }
    }

    return resultBadges;
  }
}
