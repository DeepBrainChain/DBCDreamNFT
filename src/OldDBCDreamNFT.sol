// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/console.sol";

/// @custom:oz-upgrades-from OldDBCDreamNFT
contract OldDBCDreamNFT is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    string private _name;
    string private _symbol;

    address public canUpgradeAddress;

    mapping(address => uint256[]) public address2TokenIds;
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) public level2MintedAmount;
    mapping(uint256 => uint256) public level2DBCRewardAmount;


    event Minted(address indexed to, uint256 level, uint256 amount);

    function initialize(address initialOwner) public initializer {
        __ERC1155_init("https://raw.githubusercontent.com/DeepBrainChain/DBCDreamNFT/main/resource/metadata/{id}.json");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        _name = "DBCDreamNFT111";
        _symbol = "DBCDreamNFT111";
        canUpgradeAddress = initialOwner;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        require(newImplementation != address(0), "Invalid implementation address");
        require(msg.sender == canUpgradeAddress || msg.sender == owner(), "Only canUpgradeAddress can upgrade");
    }

    function setCanUpgradeAddress(address addr) internal onlyOwner {
        canUpgradeAddress = addr;
    }

    function setLevelDBCRewardAmount() external onlyOwner {
        level2DBCRewardAmount[1] = 1_300_000 ether;
    }

    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }

    function mint(address to, uint256 level, uint256 amount) public onlyMinter {
        require(amount > 0, "Amount must be greater than zero");
        // todo add other level
//        require(level == 1, "Level must be greater than zero");
        _mint(to, level, amount, "");
        level2MintedAmount[level] += 1;
        emit Minted(to, level, amount);
    }

    function batchMint(address[] calldata targets, uint256[] calldata levels, uint256[] calldata amounts) public {
        for (uint8 i = 0; i < targets.length; i++) {
            mint(targets[i], levels[i], amounts[i]);
        }
    }

    function setMinters(address[] calldata _minters) external onlyOwner {
        for (uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }
    }

    function removeMinters(address[] calldata _minters) external onlyOwner {
        for (uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = false;
        }
    }
    function _baseURI() internal pure returns (string memory) {
        return "https://raw.githubusercontent.com/DeepBrainChain/DBCDreamNFT/main/resource/metadata/";
    }

    function uri(uint256 id) public pure override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Strings.toString(id), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getBalance(address owner, uint256 amount)
    public
    view
    returns (uint256[] memory tokenIds, uint256[] memory amounts)
    {
        require(owner != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than zero");

        uint256[] storage ownedTokenIds = address2TokenIds[owner];
        uint256 ownedCount = ownedTokenIds.length;

        tokenIds = new uint256[](ownedCount);
        amounts = new uint256[](ownedCount);

        uint256 remainingAmount = amount;
        uint256 index = 0;

        for (uint256 i = 0; i < ownedCount; i++) {
            uint256 tokenId = ownedTokenIds[i];
            uint256 balance = balanceOf(owner, tokenId);

            if (balance > 0) {
                if (balance >= remainingAmount) {
                    tokenIds[index] = tokenId;
                    amounts[index] = remainingAmount;
                    index++;
                    break;
                } else {
                    tokenIds[index] = tokenId;
                    amounts[index] = balance;
                    remainingAmount -= balance;
                    index++;
                }
            }

            // Stop if we've fulfilled the required amount
            if (remainingAmount == 0) {
                break;
            }
        }

        // Resize arrays to actual size
        assembly {
            mstore(tokenIds, index)
            mstore(amounts, index)
        }
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal override {
        super._update(from, to, ids, amounts);

        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                if (balanceOf(from, id) == 0) {
                    _removeTokenId(from, id);
                }
            }
        }

        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                if (balanceOf(to, id) > 0) {
                    if (!exits(address2TokenIds[to], id)) {
                        address2TokenIds[to].push(id);
                    }
                }
            }
        }
    }

    function _removeTokenId(address account, uint256 id) internal {
        uint256[] storage tokenIds = address2TokenIds[account];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == id) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }
    }

    function exits(uint256[] memory list, uint256 target) internal pure returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == target) {
                return true;
            }
        }
        return false;
    }

    function version() public pure returns (uint256) {
        return 1;
    }
}
