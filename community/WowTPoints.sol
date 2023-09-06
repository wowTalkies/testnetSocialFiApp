// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title WowTPoints
 * @dev A smart contract that implements a points system for users. Users can earn points, which can be used to determine their ranking on a leaderboard.
 */
contract WowTPoints is AccessControlUpgradeable, PausableUpgradeable {
    struct PointHistory {
        string category;
        string operation;
        uint256 points;
        uint256 timestamp;
    }

    uint256 public totalDistributedPoints;
    address[] private topLeaderBoard; // Sync every 24 hours based on user points

    mapping(address => PointHistory[]) private pointsHistory;
    mapping(address => uint256) private points; // Mapping to store points earned by each user
    mapping(address => uint256) private referralPoints; // Mapping to store referral points earned by each user
    mapping(string => uint256) private pointsValues;
    mapping(address => bool) private walletConnect;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

    /// @dev Modifier to restrict function access to only those with the admin role.
    modifier adminOnly() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Must have points admin role"
        );
        _;
    }

    event PointsAdded(address account, string category);
    event PointsReduced(address account, string category);

    function initialize(
        string[] memory _pointsCategory,
        uint256[] memory _pointsValues
    ) external initializer {
        require(
            _pointsValues.length == _pointsCategory.length,
            "Invalid number of parameters"
        );
        __Pausable_init();
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        for (uint256 i = 0; i < _pointsValues.length; i++) {
            pointsValues[_pointsCategory[i]] = _pointsValues[i];
        }
    }

    /**
     * @dev Adds points to a user's account.
     * @param account The address of the user's account to add points to.
     */

    function addPoints(
        address account,
        string calldata _category
    ) public adminOnly whenNotPaused {
        require(pointsValues[_category] > 0, "Category not found");
        uint256 _points = pointsValues[_category];
        uint totalPoints = points[account] + _points;
        points[account] = totalPoints;
        totalDistributedPoints = totalDistributedPoints + _points;
        pointsHistory[account].push(
            PointHistory(_category, "add", _points, block.timestamp)
        );
        if (keccak256(bytes(_category)) == keccak256(bytes("walletConnect"))) {
            require(
                !walletConnect[account],
                "Already walletConnect points added"
            );
            walletConnect[account] = true;
        }
        emit PointsAdded(account, "point");
    }

    /**
     * @dev Adds referral points to a user's account.
     * @param _account The address of the user's account to add referral points to.
     * @param _points The number of referral points to add.
     */
    function addReferralPoints(
        address _account,
        uint256 _points
    ) public adminOnly whenNotPaused {
        referralPoints[_account] += _points;
    }

    /**
     * @dev Reduces points from a user's account.
     * @param account The address of the user's account to reduce points from.
     */
    function reducePoints(
        address account,
        string memory _category
    ) public adminOnly whenNotPaused {
        require(pointsValues[_category] > 0, "Category not found");
        uint256 _points = pointsValues[_category];
        require(points[account] >= _points, "Insufficient points");
        uint256 totalPoints = points[account] - _points;
        points[account] = totalPoints;
        totalDistributedPoints = totalDistributedPoints - _points;
        pointsHistory[account].push(
            PointHistory(_category, "reduce", _points, block.timestamp)
        );
        emit PointsReduced(account, "point");
    }

    function adminAddPoints(
        address[] calldata accounts,
        uint256[] calldata _points,
        string calldata _category
    ) external adminOnly whenNotPaused {
        require(accounts.length == _points.length, "Invalid input arrays");

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 pointsToAdd = _points[i];
            string memory category = _category;

            uint256 totalPoints = points[account] + pointsToAdd;
            points[account] = totalPoints;
            totalDistributedPoints += pointsToAdd;

            pointsHistory[account].push(
                PointHistory(category, "add", pointsToAdd, block.timestamp)
            );

            emit PointsAdded(account, category);
        }
    }

    function adminReducePoints(
        address[] calldata accounts,
        uint256[] calldata _points,
        string calldata _category
    ) external adminOnly whenNotPaused {
        require(accounts.length == _points.length, "Invalid input arrays");

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 pointsToReduce = _points[i];
            string memory category = _category;

            require(points[account] >= pointsToReduce, "Insufficient points");

            uint256 totalPoints = points[account] - pointsToReduce;
            points[account] = totalPoints;
            totalDistributedPoints -= pointsToReduce;

            pointsHistory[account].push(
                PointHistory(
                    category,
                    "reduce",
                    pointsToReduce,
                    block.timestamp
                )
            );

            emit PointsReduced(account, category);
        }
    }

    function adminAddReferralPoints(
        address[] calldata _accounts,
        uint256[] calldata _points
    ) external adminOnly whenNotPaused {
        require(_accounts.length == _points.length, "Invalid input arrays");

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 referralPointsToAdd = _points[i];

            referralPoints[account] += referralPointsToAdd;
        }
    }

    function pause() public adminOnly {
        _pause();
    }

    function unpause() public adminOnly {
        _unpause();
    }

    function setTopLeaderBoards(
        address[] memory _topLeaderBoard
    ) external adminOnly whenNotPaused {
        topLeaderBoard = _topLeaderBoard;
    }

    function addPointsValue(
        string memory _category,
        uint256 _points
    ) external adminOnly whenNotPaused {
        pointsValues[_category] = _points;
    }

    function setPointsValue(
        string memory _category,
        uint256 _points
    ) external adminOnly whenNotPaused {
        require(pointsValues[_category] > 0, "Category not found");
        pointsValues[_category] = _points;
    }

    /**
     * @dev Returns the number of points earned by the specified account.
     * @param account The address of the account to check the number of points for.
     * @return The number of points earned by the specified account.
     */
    function getPoints(address account) public view returns (uint256) {
        return points[account];
    }

    /**
     * @dev Gets the referral points earned by a user.
     * @param account The address of the user's account.
     * @return The number of referral points earned.
     */
    function getReferralPoints(address account) public view returns (uint256) {
        return referralPoints[account];
    }

    function getPointsHistory(
        address account
    ) public view returns (PointHistory[] memory) {
        return pointsHistory[account];
    }

    function getPointsDetails(
        address account,
        uint256 startTime,
        uint256 endTime
    ) public view returns (PointHistory[] memory) {
        require(endTime >= startTime, "End time >= start time");

        PointHistory[] memory details;
        uint256 count = 0;
        for (uint256 i = 0; i < pointsHistory[account].length; i++) {
            if (
                pointsHistory[account][i].timestamp >= startTime &&
                pointsHistory[account][i].timestamp <= endTime
            ) {
                count++;
            }
        }

        details = new PointHistory[](count);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < pointsHistory[account].length; i++) {
            if (
                pointsHistory[account][i].timestamp >= startTime &&
                pointsHistory[account][i].timestamp <= endTime
            ) {
                details[currentIndex] = pointsHistory[account][i];
                currentIndex++;
            }
        }

        return details;
    }

    /**
     * @dev Gets the top-ranked address from the leaderboard.
     * @return The address of the top-ranked user.
     */
    function getTopRankedAddress() public view returns (address) {
        require(topLeaderBoard.length > 0, "Leaderboard is empty");
        return topLeaderBoard[0];
    }

    function getTopLeaderBoards() public view returns (address[] memory) {
        return topLeaderBoard;
    }

    function getPointsValue(
        string memory _category
    ) public view returns (uint256) {
        require(pointsValues[_category] > 0, "Category not found");
        return pointsValues[_category];
    }

    /**
     * @dev Checks whether walletConnect points have been added for a specific user or not.
     * @param account The address of the user's account to check for walletConnect points.
     * @return A boolean indicating whether walletConnect points have been added or not.
     */
    function hasWalletConnectPoints(
        address account
    ) public view returns (bool) {
        return walletConnect[account];
    }
}
