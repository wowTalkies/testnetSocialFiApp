// SPDX-License-Identifier: MIT
// solium-disable linebreak-style
pragma solidity ^0.8.17;

import { ERC4907, IERC4907, ERC721Upgradeable, IERC721Upgradeable } from './ERC4907.sol';
import { ERC721URIStorageUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import { CountersUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import { WowTCommunity } from './WowTCommunity.sol';
import { WowTPoints, PausableUpgradeable, AccessControlUpgradeable } from './WowTPoints.sol';

contract WowTAirdrop is
  ERC4907,
  PausableUpgradeable,
  ERC721URIStorageUpgradeable,
  AccessControlUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter private _tokenIdCounter;

  struct RentableItem {
    bool rentable;
    uint256 amountPerDay;
  }

  struct NFT {
    uint256 id;
    string metadataURI;
    string userName;
    address creator;
    string communityName;
    uint256 upVotes;
    uint256 downVotes;
    uint256 comments;
    mapping(address => bool) preference;
    uint256 timestamp;
  }

  struct CommunityDetails {
    string name;
    mapping(uint256 => NFT) nfts;
  }

  mapping(uint256 => string) public tokenToCommunity;
  mapping(uint256 => RentableItem) public rentables;
  mapping(string => CommunityDetails) public communityDetails;

  event IsRentable(string communityName, string category, uint256 _tokenId);
  event IsRented(string communityName, string category, uint256 _tokenId);
  event nftUpVoted(
    string communityName,
    string catagory,
    uint256 tokenId,
    uint256 upVotes
  );
  event nftDownVoted(
    string communityName,
    string catagory,
    uint256 tokenId,
    uint256 downVotes
  );
  event nftCommented(
    string communityName,
    string catagory,
    uint256 tokenId,
    uint256 comments
  );

  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); // Admin role for authorization

  /// @dev Modifier to restrict function access to only those with the admin role.
  modifier adminOnly() {
    require(hasRole(ADMIN_ROLE, _msgSender()), 'Must have airdrop admin role');
    _;
  }

  address public communityContract;
  WowTCommunity private community;
  address public pointsContract;
  WowTPoints private points;

  modifier notChangable(uint256 tokenId) {
    require(
      userOf(tokenId) == address(0),
      "You can't change the rentable status during rented period"
    );
    _;
  }

  modifier notRented(uint256 tokenId) {
    require(
      userOf(tokenId) == address(0),
      "You can't transfer during rented period"
    );
    _;
  }

  modifier tokenOwner(uint256 _tokenId) {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      'Caller is not token owner nor approved'
    );
    _;
  }

  function initialize(
    string memory name_,
    string memory symbol_,
    address _pointsContract,
    address _communityContract
  ) public initializer {
    __ERC721_init(name_, symbol_);
    communityContract = _communityContract;
    community = WowTCommunity(communityContract);
    pointsContract = _pointsContract;
    points = WowTPoints(pointsContract);
    __Pausable_init();
    _grantRole(ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function mintTo(
    string calldata _communityName,
    address to,
    string calldata metadataURI
  ) public adminOnly {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    require(
      community.checkMembership(_communityName, to),
      'You are not member in this community'
    );
    require(
      points.getPoints(to) >= points.getPointsValue('nft'),
      'Insufficient points'
    );
    string memory userName = community.getUserName(to);
    CommunityDetails storage communityDetail = communityDetails[_communityName];
    uint256 id = _tokenIdCounter.current();
    NFT storage newNFT = communityDetail.nfts[id];
    newNFT.id = id;
    newNFT.creator = to;
    newNFT.timestamp = block.timestamp;
    newNFT.userName = userName;
    newNFT.metadataURI = metadataURI;
    newNFT.communityName = _communityName;
    _safeMint(to, _tokenIdCounter.current());
    _setTokenURI(id, metadataURI);
    _tokenIdCounter.increment();
    tokenToCommunity[id] = _communityName;
    points.reducePoints(to, 'nft');
  }

  function rent(uint256 _tokenId, uint64 _expires) public payable virtual {
    string memory communityName = tokenToCommunity[_tokenId];
    uint256 dueAmount = rentables[_tokenId].amountPerDay * _expires;
    require(_tokenId < _tokenIdCounter.current(), 'Invalid token ID');
    require(msg.value == dueAmount, 'Incorrect amount');
    require(_msgSender() != ownerOf(_tokenId), 'You are the owner');
    require(userOf(_tokenId) == address(0), 'Already rented');
    require(rentables[_tokenId].rentable, 'Renting disabled for the NFT');
    payable(ownerOf(_tokenId)).transfer(dueAmount);
    UserInfo storage info = _users[_tokenId];
    info.user = _msgSender();
    info.expires = block.timestamp + (_expires * 60 * 60 * 24);
    emit UpdateUser(_tokenId, _msgSender(), _expires);
    emit IsRented(communityName, 'rent', _tokenId);
  }

  function setRentable(
    uint256 _tokenId,
    uint256 _amountPerDay,
    bool _rentable
  ) public tokenOwner(_tokenId) notChangable(_tokenId) {
    string memory communityName = tokenToCommunity[_tokenId];
    // require(!rentables[_tokenId].rentable || !(_rentable), 'Already lended');
    require(
      rentables[_tokenId].rentable != _rentable,
      'Already lended or returned'
    );
    CommunityDetails storage communityDetail = communityDetails[communityName];
    NFT storage newNFT = communityDetail.nfts[_tokenId];
    newNFT.timestamp = block.timestamp;
    rentables[_tokenId].rentable = _rentable;
    rentables[_tokenId].amountPerDay = _amountPerDay;
    emit IsRentable(communityName, 'lend', _tokenId);
  }

  function UpVoteNFT(string calldata _communityName, uint256 _tokenId) public {
    // require(_postId > 0 && _postId <= postCount, "Invalid post ID");
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    CommunityDetails storage communityDetail = communityDetails[_communityName];
    require(_tokenId <= _tokenIdCounter.current(), 'Invalid token ID');
    NFT storage nft = communityDetail.nfts[_tokenId];
    require(nft.creator != _msgSender(), 'Cannot upvote own NFT');
    require(!(nft.preference[_msgSender()]), 'Already interacted');
    nft.upVotes++;
    nft.preference[_msgSender()] = true;
    points.addPoints(_msgSender(), 'upVote');
    emit nftUpVoted(_communityName, 'nft', _tokenId, nft.upVotes);
  }

  function downVoteNFT(
    string calldata _communityName,
    uint256 _tokenId
  ) public {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    CommunityDetails storage communityDetail = communityDetails[_communityName];
    require(_tokenId <= _tokenIdCounter.current(), 'Invalid token ID');
    NFT storage nft = communityDetail.nfts[_tokenId];
    // Check if the caller is the NFT creator
    require(nft.creator != _msgSender(), 'Cannot downvote own NFT');
    require(!(nft.preference[_msgSender()]), 'Already interacted');
    nft.downVotes++;
    nft.preference[_msgSender()] = true;
    points.addPoints(_msgSender(), 'downVote');
    emit nftDownVoted(_communityName, 'nft', _tokenId, nft.downVotes);
  }

  function commentNFT(string calldata _communityName, uint256 _tokenId) public {
    require(
      community.checkCommunityExists(_communityName),
      "Community doesn't exist"
    );
    CommunityDetails storage communityDetail = communityDetails[_communityName];
    require(_tokenId <= _tokenIdCounter.current(), 'Invalid token ID');
    NFT storage nft = communityDetail.nfts[_tokenId];
    nft.comments++;
    points.addPoints(_msgSender(), 'comment');
    emit nftCommented(_communityName, 'nft', _tokenId, nft.comments);
  }

  function updateTokenMetadata(
    uint256 tokenId,
    string calldata newMetadataURI
  ) external tokenOwner(tokenId) {
    _setTokenURI(tokenId, newMetadataURI);
  }

  function getNFT(
    uint256 _tokenId
  )
    public
    view
    returns (
      string memory,
      string memory,
      address,
      string memory,
      uint256,
      uint256,
      uint256
    )
  {
    string memory communityName = tokenToCommunity[_tokenId];
    CommunityDetails storage communityDetail = communityDetails[communityName];
    require(_tokenId < _tokenIdCounter.current(), 'Invalid token ID');
    NFT storage nft = communityDetail.nfts[_tokenId];
    return (
      nft.metadataURI,
      nft.userName,
      nft.creator,
      nft.communityName,
      nft.upVotes,
      nft.downVotes,
      nft.timestamp
    );
  }

  function pause() public adminOnly {
    _pause();
  }

  function unpause() public adminOnly {
    _unpause();
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    virtual
    override(ERC721Upgradeable, IERC721Upgradeable)
    notRented(tokenId)
  {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: caller is not token owner or approved'
    );
    rentables[tokenId] = RentableItem({ rentable: false, amountPerDay: 0 });

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    virtual
    override(ERC721Upgradeable, IERC721Upgradeable)
    notRented(tokenId)
  {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: caller is not token owner or approved'
    );
    rentables[tokenId] = RentableItem({ rentable: false, amountPerDay: 0 });
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public
    virtual
    override(ERC721Upgradeable, IERC721Upgradeable)
    notRented(tokenId)
  {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: caller is not token owner or approved'
    );
    rentables[tokenId] = RentableItem({ rentable: false, amountPerDay: 0 });

    _safeTransfer(from, to, tokenId, data);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId, 1);
  }

  function _burn(
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
    super._burn(tokenId);
  }

  function tokenURI(
    uint256 tokenId
  )
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(
      ERC721Upgradeable,
      ERC721URIStorageUpgradeable,
      AccessControlUpgradeable
    )
    returns (bool)
  {
    return
      interfaceId == type(IERC4907).interfaceId ||
      super.supportsInterface(interfaceId);
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

  // development

  // function editRentStatus(
  //   uint256 _tokenId,
  //   uint256 _expires
  // ) external onlyOwner {
  //   // string memory communityName = tokenToCommunity[_tokenId];
  //   require(_tokenId < _tokenIdCounter.current(), 'Invalid token ID');
  //   UserInfo storage info = _users[_tokenId];
  //   info.user = _msgSender();
  //   info.expires = _expires;
  //   // emit UpdateUser(_tokenId, _msgSender(), _expires);
  //   // emit IsRented(communityName, 'rent', _tokenId);
  // }
}
