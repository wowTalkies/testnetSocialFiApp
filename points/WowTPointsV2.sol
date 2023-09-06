// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// /**
//  * @title WowTPoints
//  * @dev A smart contract that implements a points system for users. Users can earn points, which can be used to determine their ranking on a leaderboard.
//  */
// contract WowTPointsV2 is OwnableUpgradeable, AccessControlUpgradeable {
//     struct PointHistory {
//         string category;
//         uint256 points;
//         uint256 timestamp;
//     }

//     struct Points {
//         uint256 levelOnePoints;
//         uint256 levelTwoPoints;
//         uint256 activeUserPoints;
//         uint256 minimumPointsForConvertion;
//         uint256 postPoints;
//         uint256 upVotePoints;
//         uint256 downVotePoints;
//         uint256 commentPoints;
//         uint256 adPoints;
//         uint256 pollPoints;
//         uint256 sharePoints;
//         uint256 ratePoints;
//         uint256 votePoints;
//         uint256 registerPoints;
//         uint256 walletConnectPoints;
//     }

//     Points public pointValues;

//     address[10] public topLeaderBoardAddress; // Array to store top 10 leaderboard positions

//     mapping(address => PointHistory[]) public pointsHistory;
//     mapping(address => uint256) private points; // Mapping to store points earned by each user
//     mapping(address => uint256) private referralPoints; // Mapping to store referral points earned by each user

//     bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

//     /// @dev Modifier to restrict function access to only those with the admin role.
//     modifier adminOnly() {
//         require(hasRole(ADMIN_ROLE, _msgSender()), "Must have admin role");
//         _;
//     }

//     event pointsAdded(address account, string category);

//     function initialize(uint256[] memory _pointValues) external initializer {
//         require(_pointValues.length == 15, "Invalid number of parameters");

//         __Ownable_init();
//         _grantRole(ADMIN_ROLE, _msgSender());
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

//         pointValues = Points(
//             _pointValues[0],
//             _pointValues[1],
//             _pointValues[2],
//             _pointValues[3],
//             _pointValues[4],
//             _pointValues[5],
//             _pointValues[6],
//             _pointValues[7],
//             _pointValues[8],
//             _pointValues[9],
//             _pointValues[10],
//             _pointValues[11],
//             _pointValues[12],
//             _pointValues[13],
//             _pointValues[14]
//         );
//     }

//     /**
//      * @dev Adds points to a user's account.
//      * @param account The address of the user's account to add points to.
//      * @param _points The number of points to add.
//      */

//     function addPoints(
//         address account,
//         uint256 _points,
//         string memory category
//     ) public adminOnly {
//         uint totalPoints = points[account] + _points;
//         points[account] = totalPoints;
//         pointsHistory[account].push(
//             PointHistory(category, _points, block.timestamp)
//         );
//         updateLeaderBoard(account, totalPoints);
//         emit pointsAdded(account, "point");
//     }

//     /**
//      * @dev Adds active user points to a user's account.
//      * @param account The address of the user's account to add points to.
//      */
//     function addActiveUserPoints(
//         address account,
//         string memory _catagory
//     ) external onlyOwner {
//         addPoints(account, pointValues.activeUserPoints, _catagory);
//     }

//     /**
//      * @dev Adds referral points to a user's account.
//      * @param _account The address of the user's account to add referral points to.
//      * @param _points The number of referral points to add.
//      */
//     function addReferralPoints(
//         address _account,
//         uint256 _points
//     ) public adminOnly {
//         referralPoints[_account] += _points;
//     }

//     /**
//      * @dev Reduces points from a user's account.
//      * @param account The address of the user's account to reduce points from.
//      * @param _points The number of points to reduce.
//      */
//     function reducePoints(address account, uint256 _points) public adminOnly {
//         require(_points > 0, "points must be greater than zero");
//         uint256 totalPoints = points[account];
//         require(totalPoints >= _points, "points are too low to reduce");
//         totalPoints -= _points;
//         points[account] = totalPoints;

//         // Check if the user is in the top leaderboard
//         bool isInTopLeaderboard = false;
//         uint256 replaceIndex;
//         for (uint256 i = 0; i < topLeaderBoardAddress.length; i++) {
//             if (topLeaderBoardAddress[i] == account) {
//                 isInTopLeaderboard = true;
//                 replaceIndex = i;
//                 break;
//             }
//         }

//         if (isInTopLeaderboard) {
//             // Remove the user from the leaderboard
//             for (
//                 uint256 j = replaceIndex;
//                 j < topLeaderBoardAddress.length - 1;
//                 j++
//             ) {
//                 topLeaderBoardAddress[j] = topLeaderBoardAddress[j + 1];
//             }

//             // Find the correct position to insert the user based on the updated points
//             uint256 insertIndex = 0;
//             while (
//                 insertIndex < topLeaderBoardAddress.length &&
//                 totalPoints < getPoints(topLeaderBoardAddress[insertIndex])
//             ) {
//                 insertIndex++;
//             }

//             // Insert the user at the correct position
//             if (insertIndex < topLeaderBoardAddress.length) {
//                 topLeaderBoardAddress[insertIndex] = account;
//             }
//         }
//     }

//     /**
//      * @dev Internal function to update the leaderboard based on a user's points.
//      * @param account Address of the user to update leaderboard for
//      * @param totalPoints Amount of points earned by the user
//      */

//     // function updateLeaderBoard(address account, uint256 totalPoints) private {
//     //     for (uint i = 0; i < topLeaderBoardAddress.length; i++) {
//     //         if (topLeaderBoardAddress[i] == account) {
//     //             delete topLeaderBoardAddress[i];
//     //             for (uint m = i; m < topLeaderBoardAddress.length - 1; m++) {
//     //                 topLeaderBoardAddress[m] = topLeaderBoardAddress[m + 1];
//     //             }
//     //         }
//     //     }
//     //     uint j = 0;
//     //     for (j; j < topLeaderBoardAddress.length; j++) {
//     //         if (getPoints(topLeaderBoardAddress[j]) < totalPoints) {
//     //             break;
//     //         }
//     //     }
//     //     for (uint k = topLeaderBoardAddress.length - 1; k > j; k--) {
//     //         topLeaderBoardAddress[k] = topLeaderBoardAddress[k - 1];
//     //     }
//     //     topLeaderBoardAddress[j] = account;
//     // }

//     function updateLeaderBoard(address account, uint256 totalPoints) private {
//         // Check if the user is already in the leaderboard
//         uint256 userIndex = topLeaderBoardAddress.length;
//         for (uint256 i = 0; i < topLeaderBoardAddress.length; i++) {
//             if (topLeaderBoardAddress[i] == account) {
//                 userIndex = i;
//                 break;
//             }
//         }

//         if (userIndex < topLeaderBoardAddress.length) {
//             // User is already in the leaderboard, remove their address
//             for (
//                 uint256 i = userIndex;
//                 i < topLeaderBoardAddress.length - 1;
//                 i++
//             ) {
//                 topLeaderBoardAddress[i] = topLeaderBoardAddress[i + 1];
//             }
//         } else if (topLeaderBoardAddress.length < 10) {
//             // If the leaderboard is not full, add the user's address at the end
//             userIndex = topLeaderBoardAddress.length;
//         } else {
//             // If the leaderboard is full, check if the user's points are lower than the lowest on the leaderboard
//             uint256 lowestPoints = getPoints(topLeaderBoardAddress[9]);
//             if (totalPoints <= lowestPoints) {
//                 return;
//             }
//             userIndex = 9;
//         }

//         // Find the correct position to insert the user based on the updated points
//         while (
//             userIndex > 0 &&
//             totalPoints > getPoints(topLeaderBoardAddress[userIndex - 1])
//         ) {
//             topLeaderBoardAddress[userIndex] = topLeaderBoardAddress[
//                 userIndex - 1
//             ];
//             userIndex--;
//         }

//         // Insert the user's address at the correct position
//         topLeaderBoardAddress[userIndex] = account;
//     }

//     /**
//      * @dev Returns the number of points earned by the specified account.
//      * @param account The address of the account to check the number of points for.
//      * @return The number of points earned by the specified account.
//      */
//     function getPoints(address account) public view returns (uint256) {
//         return points[account];
//     }

//     /**
//      * @dev Gets the referral points earned by a user.
//      * @param account The address of the user's account.
//      * @return The number of referral points earned.
//      */
//     function getReferralPoints(address account) public view returns (uint256) {
//         return referralPoints[account];
//     }

//     function getPointsDetails(
//         address account,
//         uint256 startTime,
//         uint256 endTime
//     ) public view returns (string[] memory, uint256[] memory) {
//         require(endTime >= startTime, "End time >= start time");

//         uint256[] memory pointsInRange;
//         string[] memory categoriesInRange;
//         uint256[] memory timestampsInRange;

//         uint256 count = 0;
//         for (uint256 i = 0; i < pointsHistory[account].length; i++) {
//             if (
//                 pointsHistory[account][i].timestamp >= startTime &&
//                 pointsHistory[account][i].timestamp <= endTime
//             ) {
//                 count++;
//             }
//         }

//         pointsInRange = new uint256[](count);
//         categoriesInRange = new string[](count);
//         timestampsInRange = new uint256[](count);

//         uint256 currentIndex = 0;
//         for (uint256 i = 0; i < pointsHistory[account].length; i++) {
//             if (
//                 pointsHistory[account][i].timestamp >= startTime &&
//                 pointsHistory[account][i].timestamp <= endTime
//             ) {
//                 pointsInRange[currentIndex] = pointsHistory[account][i].points;
//                 categoriesInRange[currentIndex] = pointsHistory[account][i]
//                     .category;
//                 timestampsInRange[currentIndex] = pointsHistory[account][i]
//                     .timestamp;
//                 currentIndex++;
//             }
//         }

//         return (categoriesInRange, pointsInRange);
//     }

//     /**
//      * @dev Returns the address of the top user on the leaderboard.
//      * @return The address of the top user.
//      */
//     function getLeaderBoard() public view returns (address) {
//         return topLeaderBoardAddress[0];
//     }

//     /**
//      * @dev Returns an array of the top 10 addresses on the leaderboard.
//      * @return An array of the top 10 addresses on the leaderboard.
//      */
//     function getTopLeaderBoards() public view returns (address[10] memory) {
//         return topLeaderBoardAddress;
//     }

//     /**
//      * @dev Sets the point threshold for Level 1.
//      * @param newLevelOnePoints The new point threshold for Level 1.
//      */
//     function setLevelOnePoints(uint256 newLevelOnePoints) external onlyOwner {
//         pointValues.levelOnePoints = newLevelOnePoints;
//     }

//     /**
//      * @dev Sets the point threshold for Level 2.
//      * @param newLevelTwoPoints The new point threshold for Level 2.
//      */
//     function setLevelTwoPoints(uint256 newLevelTwoPoints) external onlyOwner {
//         pointValues.levelTwoPoints = newLevelTwoPoints;
//     }

//     /**
//      * @dev Sets the number of points earned by active users.
//      * @param newActiveUserPoints The new number of points earned by active users.
//      */
//     function setActiveUserPoints(
//         uint256 newActiveUserPoints
//     ) external onlyOwner {
//         pointValues.activeUserPoints = newActiveUserPoints;
//     }

//     /**
//      * @dev Sets the minimum number of points required to convert to the ERC20 token.
//      * @param newMinimumPointsForConvertion The new minimum number of points required to convert to the ERC20 token.
//      */
//     function setMinimumPointsForConvertion(
//         uint256 newMinimumPointsForConvertion
//     ) external onlyOwner {
//         pointValues.minimumPointsForConvertion = newMinimumPointsForConvertion;
//     }
// }
