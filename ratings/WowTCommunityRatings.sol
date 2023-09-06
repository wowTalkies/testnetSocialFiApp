// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {WowTCommunity} from "./WowTCommunity.sol";
import {WowTPoints, AccessControlUpgradeable, PausableUpgradeable} from "./WowTPoints.sol";

contract WowTCommunityRatings is AccessControlUpgradeable, PausableUpgradeable {
    //Movie
    struct Movie {
        uint256 id;
        string movieName;
        string movieImgUrl;
        uint256 rating;
        mapping(address => bool) preference;
        uint256 upVotes;
        uint256 downVotes;
        uint256 comments;
        uint256 avgReview;
        uint256 totalReviewed;
        address[] users;
        string communityName;
        uint256 timestamp;
        address creator;
    }
    //User Review object
    struct UserInput {
        uint256 rating;
        string comments;
        uint256 dateOfReview;
        bool isMovieReviewedByUser;
    }

    //   Movie newMovie;
    UserInput public newInput;
    uint256 public movieCount;

    //   mapping(uint256 => Movie) movieDetails;
    //   uint256[] public MovieIds;
    mapping(uint256 => mapping(address => UserInput)) public userReview;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin role for authorization

    address public communityContract;
    WowTCommunity private community;
    address public pointsContract;
    WowTPoints private points;

    struct CommunityDetails {
        string name;
        // uint256256[] postIds;
        mapping(uint256 => Movie) movies;
        // uint256256 postCount;
    }

    mapping(string => CommunityDetails) public communityDetails;

    event addMovieEvent(string communityName, string catagory, uint256 movieId);
    event reviewMovieEvent(
        string communityName,
        string catagory,
        uint256 movieId
    );
    event movieUpVoted(
        string communityName,
        string catagory,
        uint256 movieId,
        uint256 upVotes
    );
    event postDownVoted(
        string communityName,
        string catagory,
        uint256 movieId,
        uint256 upVotes
    );
    event movieCommented(
        string communityName,
        string catagory,
        uint256 movieId,
        uint256 upVotes
    );

    /// @dev Modifier to restrict function access to only those with the admin role.
    modifier adminOnly() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "Must have rating admin role"
        );
        _;
    }

    function initialize(
        address _pointsContract,
        address _communityContract
    ) public initializer {
        __Pausable_init();
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        communityContract = _communityContract;
        community = WowTCommunity(communityContract);
        pointsContract = _pointsContract;
        points = WowTPoints(_pointsContract);
    }

    // constructor() public {
    //     movieCount = 0;
    // }

    function addMovie(
        string memory _communityName,
        string memory _movieName,
        string memory _imageUrl
    ) public adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        require(
            keccak256(bytes(_movieName)) != keccak256(""),
            "Invalid Movie Name"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        Movie storage newMovie = communityDetail.movies[movieCount];
        // movieCount++;
        // uint256 movieId = movieCount;
        newMovie.id = movieCount;
        newMovie.movieName = _movieName;
        newMovie.movieImgUrl = _imageUrl;
        newMovie.timestamp = block.timestamp;
        newMovie.creator = _msgSender();
        // newMovie.avgRating = 0;
        // newMovie.totalReviewed = 0;
        // newMovie.users.push(_msgSender());

        // MovieIds.push(movieId);
        // movieDetails[movieId] = newMovie;
        movieCount++;

        emit addMovieEvent(_communityName, "rate", newMovie.id);
    }

    function reviewMovie(
        string memory _communityName,
        uint256 _movieId,
        uint256 _rating,
        string memory _comments
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        //Need to add the Movie name already exit check here
        require(
            _rating > 0 && _rating <= 50,
            "Movie rating should be in 1-5 range !"
        );
        require(
            userReview[_movieId][_msgSender()].isMovieReviewedByUser == false,
            "Movie already reviewed by user !"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        Movie storage movie = communityDetail.movies[_movieId];
        require(_msgSender() != movie.creator, "Cannot review own movie");
        require(_movieId < movieCount, "Invalid movie ID");
        movie.rating += _rating; //* 10;
        movie.totalReviewed++;
        movie.avgReview = movie.rating / movie.totalReviewed;
        // movie.users.push(_msgSender());

        newInput.rating = _rating;
        newInput.comments = _comments;
        newInput.dateOfReview = block.timestamp;
        newInput.isMovieReviewedByUser = true;
        userReview[_movieId][_msgSender()] = newInput;
        points.addPoints(_msgSender(), "rate");
        emit reviewMovieEvent(_communityName, "rate", _movieId);
    }

    function upVoteMovie(
        string calldata _communityName,
        uint256 _movieId
    ) public whenNotPaused {
        // require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_movieId <= movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];
        require(_msgSender() != movie.creator, "Cannot upvote your own movie");
        require(!(movie.preference[_msgSender()]), "Already interacted");
        movie.upVotes++;
        movie.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "upVote");
        emit movieUpVoted(_communityName, "rate", _movieId, movie.upVotes);
    }

    function downVoteMovie(
        string calldata _communityName,
        uint256 _movieId
    ) public whenNotPaused {
        //require(_postId > 0 && _postId <= postCount, "Invalid post ID");
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_movieId <= movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];
        require(
            _msgSender() != movie.creator,
            "Cannot downvote your own movie"
        );
        require(!(movie.preference[_msgSender()]), "Already interacted");
        movie.downVotes++;
        movie.preference[_msgSender()] = true;
        points.addPoints(_msgSender(), "downVote");
        emit postDownVoted(_communityName, "rate", _movieId, movie.downVotes);
    }

    function commentMovie(
        string calldata _communityName,
        uint256 _movieId
    ) public whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_movieId <= movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];
        movie.comments++;
        points.addPoints(_msgSender(), "comment");
        emit movieCommented(_communityName, "rate", _movieId, movie.comments);
    }

    function getMovieCount() public view returns (uint256) {
        return movieCount;
    }

    function getUserComments(
        uint256 _movieId,
        address _user
    ) public view returns (string memory) {
        require(_movieId >= 0, "movieId should be greater than zero");

        return userReview[_movieId][_user].comments;
    }

    function getUserRating(
        uint256 _movieId,
        address _user
    ) public view returns (uint256) {
        require(_movieId >= 0, "movieId should be greater than zero");

        return userReview[_movieId][_user].rating;
    }

    function getUserDateOfReview(
        uint256 _movieId,
        address user
    ) public view returns (uint256) {
        require(_movieId >= 0, "movieId should be greater than zero");

        return userReview[_movieId][user].dateOfReview;
    }

    function getMovie(
        string memory _communityName,
        uint256 _movieId
    )
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];

        require(_movieId < movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];
        return (
            movie.communityName,
            movie.movieName,
            movie.movieImgUrl,
            movie.rating,
            movie.upVotes,
            movie.downVotes,
            movie.avgReview,
            movie.totalReviewed,
            movie.timestamp,
            movie.creator
        );
    }

    function setCommunityContractAddress(
        address _communityContract
    ) external adminOnly {
        communityContract = _communityContract;
        community = WowTCommunity(_communityContract);
    }

    function setPointsContractAddress(
        address _pointsContract
    ) external adminOnly {
        pointsContract = _pointsContract;
        points = WowTPoints(_pointsContract);
    }

    function setMovieName(
        string memory _communityName,
        uint256 _movieId,
        string memory _newMovieName
    ) external adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_movieId < movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];

        movie.movieName = _newMovieName;

        // Emit an event to indicate that the movie name has been updated
        emit addMovieEvent(_communityName, "rate", _movieId);
    }

    function setMovieImage(
        string memory _communityName,
        uint256 _movieId,
        string memory _newImageUrl
    ) external adminOnly whenNotPaused {
        require(
            community.checkCommunityExists(_communityName),
            "Community doesn't exist"
        );
        CommunityDetails storage communityDetail = communityDetails[
            _communityName
        ];
        require(_movieId < movieCount, "Invalid movie ID");
        Movie storage movie = communityDetail.movies[_movieId];

        movie.movieImgUrl = _newImageUrl;

        // Emit an event to indicate that the movie image URL has been updated
        emit addMovieEvent(_communityName, "rate", _movieId);
    }

    // development

    // function editMovieDetails(
    //   string memory _communityName,
    //   uint256 _movieId,
    //   string memory _movieName,
    //   string memory _imageUrl
    // ) external onlyOwner {
    //   require(
    //     community.checkCommunityExists(_communityName),
    //     "Community doesn't exist"
    //   );
    //   require(
    //     keccak256(bytes(_movieName)) != keccak256(''),
    //     'Invalid Movie Name'
    //   );
    //   CommunityDetails storage communityDetail = communityDetails[_communityName];
    //   require(_movieId < movieCount, 'Invalid movie ID');
    //   Movie storage movie = communityDetail.movies[_movieId];
    //   // movieCount++;
    //   // uint256 movieId = movieCount;
    //   // newMovie.id = movieCount;
    //   movie.movieName = _movieName;
    //   movie.movieImgUrl = _imageUrl;

    //   emit addMovieEvent(_communityName, 'rate', movie.id);
    // }
}
