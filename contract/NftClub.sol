pragma solidity ^0.4.25;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly {retptr := add(ret, 32)}
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {retptr := add(ret, 32)}

        for (i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    function stringToBytes(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function equal(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length == 0 && bytes(b).length == 0) {
            return true;
        }
        
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return stringToBytes(a) == stringToBytes(b);
        }
    }
    
    function uint2String(uint256 i) internal pure returns (string c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        c = string(bstr);
    }
}

library JSON {
    
    function uintsToJson(string memory key, uint256[] vals) internal pure returns (string memory json) {
        strings.slice[] memory valParts = new strings.slice[](vals.length);
        for(uint256 i=0;i<vals.length;i++) {
            valParts[i] = strings.toSlice(strings.uint2String(vals[i]));
        }
        string memory valsJson = strings.concat(strings.toSlice("["), strings.toSlice(strings.join(strings.toSlice(","), valParts)));
        valsJson = strings.concat(strings.toSlice(valsJson), strings.toSlice("]"));


        strings.slice[] memory parts = new strings.slice[](2);
        parts[0] = strings.toSlice(key);
        parts[1] = strings.toSlice(valsJson);

        json = strings.join(strings.toSlice(":"), parts);
    }

    function uintToJson(string memory key, uint256 val) internal pure returns (string memory json) {
        strings.slice[] memory parts = new strings.slice[](2);
        parts[0] = strings.toSlice(key);
        parts[1] = strings.toSlice(strings.uint2String(val));

        json = strings.join(strings.toSlice(":"), parts);
    }
    
    function toJsonString(string memory key, string val) internal pure returns (string memory json) {
        strings.slice[] memory parts = new strings.slice[](2);
        parts[0] = strings.toSlice(key);
        
        strings.slice[] memory strs = new strings.slice[](3);
        strs[0] = strings.toSlice("\"");
        strs[1] = strings.toSlice(val);
        strs[2] = strings.toSlice("\"");
        parts[1] = strings.toSlice(strings.join(strings.toSlice(""), strs));

        json = strings.join(strings.toSlice(":"), parts);
    }
    
    function toJsonMap(string[] memory vals) internal pure returns (string memory json){
        strings.slice[] memory parts = new strings.slice[](vals.length);
        for(uint i=0;i<vals.length;i++) {
            parts[i] = strings.toSlice(vals[i]);
        }
        json = strings.concat(strings.toSlice("{"), strings.toSlice(strings.join(strings.toSlice(","), parts)));
        json = strings.concat(strings.toSlice(json), strings.toSlice("}"));
        
    }
    
    function toJsonList(string[] memory  list) internal pure returns (string memory json) {
        strings.slice[] memory parts = new strings.slice[](list.length);
        for(uint i=0;i<list.length;i++) {
            parts[i] = strings.toSlice(list[i]);
        }
        json = strings.concat(strings.toSlice("["), strings.toSlice(strings.join(strings.toSlice(","), parts)));
        json = strings.concat(strings.toSlice(json), strings.toSlice("]"));
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul error");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div error");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub error");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add error");

        return c;
    }
}


library Utils {

    function sameDay(uint day1, uint day2) internal pure returns (bool){
        return day1 / 24 / 3600 == day2 / 24 / 3600;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        uint charCount = 0;
        bytes memory bytesString = new bytes(32);
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            } else if (charCount != 0) {
                break;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];

        }
        return string(bytesStringTrimmed);
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;

    }
}

contract Ownable {

    address public owner;
    address public manager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyManager() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function setManager(address newManager) public onlyOwner {
        manager = newManager;
    }
}

contract SeroInterface {

    bytes32 private topic_sero_issueToken = 0x3be6bf24d822bcd6f6348f6f5a5c2d3108f04991ee63e80cde49a8c4746a0ef3;
    bytes32 private topic_sero_balanceOf = 0xcf19eb4256453a4e30b6a06d651f1970c223fb6bd1826a28ed861f0e602db9b8;
    bytes32 private topic_sero_send = 0x868bd6629e7c2e3d2ccf7b9968fad79b448e7a2bfb3ee20ed1acbc695c3c8b23;
    bytes32 private topic_sero_currency = 0x7c98e64bd943448b4e24ef8c2cdec7b8b1275970cfe10daf2a9bfa4b04dce905;

    function sero_msg_currency() internal returns (string) {
        bytes memory tmp = new bytes(32);
        bytes32 b32;
        assembly {
            log1(tmp, 0x20, sload(topic_sero_currency_slot))
            b32 := mload(tmp)
        }
        return Utils.bytes32ToString(b32);
    }

    function sero_issueToken(uint256 _total, string memory _currency) internal returns (bool success){
        bytes memory temp = new bytes(64);
        assembly {
            mstore(temp, _currency)
            mstore(add(temp, 0x20), _total)
            log1(temp, 0x40, sload(topic_sero_issueToken_slot))
            success := mload(add(temp, 0x20))
        }
        return;
    }

    function sero_balanceOf(string memory _currency) internal view returns (uint256 amount){
        bytes memory temp = new bytes(32);
        assembly {
            mstore(temp, _currency)
            log1(temp, 0x20, sload(topic_sero_balanceOf_slot))
            amount := mload(temp)
        }
        return;
    }

    function sero_send_token(address _receiver, string memory _currency, uint256 _amount) internal returns (bool success){
        return sero_send(_receiver, _currency, _amount, "", 0);
    }

    function sero_send(address _receiver, string memory _currency, uint256 _amount, string memory _category, bytes32 _ticket) internal returns (bool success){
        bytes memory temp = new bytes(160);
        assembly {
            mstore(temp, _receiver)
            mstore(add(temp, 0x20), _currency)
            mstore(add(temp, 0x40), _amount)
            mstore(add(temp, 0x60), _category)
            mstore(add(temp, 0x80), _ticket)
            log1(temp, 0xa0, sload(topic_sero_send_slot))
            success := mload(add(temp, 0x80))
        }
        return;
    }

}

interface CodeService {

    function encode(uint64 n) external view returns (string);

    function decode(string code) external view returns (uint);
}


contract UBS is Ownable, SeroInterface {

    using SafeMath for uint256;

    uint256 private constant levels = 20;

    string private constant EMPTY = "";
    string private constant SERO_CURRENCY = "NFTCLUB";
    uint256 private constant minAmount = 1e19;

    CodeService private codeService;

    struct Investor {
        uint256 id;
        uint256 parentId;
        uint256 value;
        uint256 returnValue;
        uint256 totalAynamicReward;
        uint256 staticReward;
        uint256 staticTimestamp;
        
        uint256 dynamicReward;
        uint256 dynamicTimestamp;

        uint256 canWithdrawValue;

        uint256[] achievements;
    }

    Investor[] private investors;
    mapping(address => uint256) private indexs;
    mapping(address => uint256) private harvests;


    uint256 private preTotalShare;
    uint256 private preRewardAmount;
 
    uint256 private totalShare;
    uint256 private lastUpdated;

    uint256 private triggerStaticNum = 20;
    
    uint256 private cash;
    
    uint256 private ratio = 10000;

    constructor(address _codeServiceAddr) public {
        codeService = CodeService(_codeServiceAddr);
        investors.push(Investor({id : 0, parentId : 0, value : 0, returnValue : 0, totalAynamicReward:0, staticReward:0, staticTimestamp : 0, dynamicReward:0, dynamicTimestamp:0, canWithdrawValue : 0, achievements : new uint256[](0)}));
    }
    
    function setRatio(uint newRatio) public onlyManager {
        ratio = newRatio;
    }

    function registerNode(address addr) public onlyOwner {
        require(!Utils.isContract(addr));
        uint256 index = investors.length;
        indexs[addr] = index;
        investors.push(Investor({id : index, parentId : 0, value : 0, returnValue : 0, totalAynamicReward:0, staticReward:0, staticTimestamp : now, dynamicReward:0, dynamicTimestamp:now, canWithdrawValue : 0, achievements : new uint256[](0)}));
    }

    function details(string memory code) public view returns (string json) {
        if(indexs[msg.sender] == 0) {
            return;
        }
        
        Investor storage self = investors[indexs[msg.sender]];
        if (!strings.equal(code, EMPTY)) {
 
            uint256 id = codeService.decode(code);
            require(id > 0 && id < investors.length);

            self = investors[id];
            while (id != indexs[msg.sender]) {
                if (id == 0) {
                    return;
                }
                id = investors[id].parentId;
            }
        }
        
        string[] memory vals = new string[](11);
        vals[0] = JSON.toJsonString("\"selfCode\"",codeService.encode(uint64(self.id)));
        vals[1] = JSON.toJsonString("\"parentCode\"",self.parentId == 0 ? "\"\"" : codeService.encode(uint64(self.parentId)));
        vals[2] = JSON.uintToJson("\"value\"", self.value);
        vals[3] = JSON.uintToJson("\"returnValue\"", self.returnValue);
        vals[4] = JSON.uintToJson("\"totalAynamicReward\"", self.totalAynamicReward);
        
        uint256 canWithdraw = self.canWithdrawValue;
  
        vals[5] = JSON.uintToJson("\"canWithdraw\"", canWithdraw);
 
        if(Utils.sameDay(self.staticTimestamp, now)) {
            vals[6] = JSON.uintToJson("\"staticReward\"", self.staticReward);
        } else {
            vals[6] = JSON.uintToJson("\"staticReward\"", calceStaticReward(self, self.value.sub(self.returnValue)));
        }
        
        if(Utils.sameDay(self.dynamicTimestamp, now)) {
            vals[7] = JSON.uintToJson("\"dynamicReward\"", self.dynamicReward);
        } else {
            vals[7] = JSON.uintToJson("\"dynamicReward\"", 0);
        }
        
        vals[8] = JSON.uintToJson("\"staticTimestamp\"", self.staticTimestamp);
        vals[9] = JSON.uintsToJson("\"achievements\"", self.achievements);
        vals[10] = JSON.uintToJson("\"harvest\"", harvests[msg.sender]);
        
        json = JSON.toJsonMap(vals);
        return;
    }

    function _beforeUpdate() internal {
        if (!Utils.sameDay(now, lastUpdated)) {
            preRewardAmount = balanceOfPool().div(100);
            preTotalShare = totalShare;
            lastUpdated = now;
        }
    }

   
    function calceStaticReward(Investor storage self, uint256 maxReward) internal view returns (uint256 value){
        if(preRewardAmount == 0 || preTotalShare == 0) {
            return 0;
        }

        value = Utils.min(maxReward, self.value.sub(self.returnValue).mul(preRewardAmount).div(preTotalShare));
        if (value.add(self.returnValue) > self.value) {
            value = self.value.sub(self.returnValue);
        }
    }
    
    function payStaticReward(Investor storage self, uint256 maxReward) internal returns (uint256 value){
        self.staticTimestamp = now;
        value = calceStaticReward(self, maxReward);
        self.staticReward = value;
        
        if (self.parentId > 0) {
            Investor storage current = self;
            uint256 height = 0;
            while (current.parentId != 0 && height < levels) {
                current = investors[current.parentId];
                if(current.achievements[height] > value) {
                    current.achievements[height] = current.achievements[height].sub(value);
                } else {
                    current.achievements[height] = 0;
                }
                height++;
            }
        }
        
        self.canWithdrawValue = self.canWithdrawValue.add(value);
        self.returnValue = self.returnValue.add(value);
    }
    
    function payDynamicReward(Investor storage self, uint256 maxReward, uint256 height) internal returns (uint256 value) {
      
        if(self.value.sub(self.returnValue).div(3) >=1e23) {
            value = maxReward;
        } else {
            value = calceStaticReward(self, maxReward);
        }
        
        if(height > 0) {
            value = value.div(10);
        }

        if(Utils.sameDay(self.dynamicTimestamp, now)) {
            self.dynamicReward = self.dynamicReward.add(value);
        } else {
            self.dynamicReward = value;
            self.dynamicTimestamp = now;
        }
        
        self.canWithdrawValue = self.canWithdrawValue.add(value);
        self.totalAynamicReward = self.totalAynamicReward.add(value);
    }

    function calceReward(Investor storage self) internal returns (uint256 , uint256) {
        uint256 reward = payStaticReward(self, self.value.sub(self.returnValue));
        
        uint256 amount = reward;
        
        if (self.parentId > 0) {
            uint256 value;
            Investor storage current = investors[self.parentId];
            value = payDynamicReward(current, reward, 0);
           
            amount = amount.add(value);

            uint256 height = 1;
            while (current.parentId != 0 && height < levels) {
                current = investors[current.parentId];
                if (current.achievements[0].div(1e22) > height && current.returnValue < current.value) {
                    value = payDynamicReward(current, reward, height);
                    amount = amount.add(value);
                }
                height++;
            }
        }
        
        return (reward, amount);
    }

    function triggerStaticProfit() public {

        uint256 id = indexs[msg.sender];
        require(id != 0);
        
        _beforeUpdate();

        if (preTotalShare == 0 || preRewardAmount == 0) {
            return;
        }


        uint256 allShare;
        uint256 allProfit;
        for (uint256 i = id; i < Utils.min(investors.length, id + triggerStaticNum); i++) {
            Investor storage self = investors[i];
            if(!Utils.sameDay(self.staticTimestamp, now) && self.value > self.returnValue) {
                (uint256 share, uint256 profit) = calceReward(self);
                allShare = allShare.add(share);
                allProfit = allProfit.add(profit);
            }
        }
        cash = cash.add(allProfit);
        totalShare = totalShare.sub(allShare);
    }

    function withdraw() public {
        uint256 index = indexs[msg.sender];
        require(index != 0);
        Investor storage self = investors[index];
        
        uint256 value = self.canWithdrawValue;
        
        cash = cash.sub(self.canWithdrawValue);
        self.canWithdrawValue = 0;
    
        require(sero_send_token(msg.sender, SERO_CURRENCY, value));
    }


    function register(string memory code) internal {
        require(!Utils.isContract(msg.sender));

        uint256 parentIndex = codeService.decode(code);
        require(parentIndex > 0 && parentIndex < investors.length);

        Investor storage parent = investors[parentIndex];
        uint256 index = investors.length;

        indexs[msg.sender] = index;
        investors.push(Investor({id : index, parentId : parentIndex, value : 0, returnValue : 0, totalAynamicReward:0, staticReward:0, staticTimestamp : now, dynamicReward:0, dynamicTimestamp:now, canWithdrawValue : 0, achievements : new uint256[](0)}));
    }
    
    function recharge() public payable {
        require(strings.equal(sero_msg_currency(), "KINGCLUB"));
    }
    
    function balanceOfKING() public view returns(uint) {
        return sero_balanceOf("KINGCLUB");
    }
    
    function harvest() public {
        uint value = harvests[msg.sender];
        require(value > 0, "value is zero");
        harvests[msg.sender] = 0;
        require(sero_send_token(msg.sender, "KINGCLUB", value));
    }

    function reinvest(uint256 reinvestValue) public {
        require(minAmount <= reinvestValue || reinvestValue == 0);
     
        uint256 index = indexs[msg.sender];
        require(index != 0);
        Investor storage self = investors[index];
        
        if(reinvestValue == 0) {
            reinvestValue = self.canWithdrawValue;
            require(minAmount <= reinvestValue);
        }

        require(self.canWithdrawValue >= reinvestValue);
        self.canWithdrawValue = self.canWithdrawValue.sub(reinvestValue);
        cash = cash.sub(reinvestValue);
        
        investValue(self, reinvestValue);
        
        harvests[msg.sender] = harvests[msg.sender].add(reinvestValue/ratio);
  
    }

    function invest(string memory code) public payable {
        require(strings.equal(SERO_CURRENCY, sero_msg_currency()));
        require(msg.value >= minAmount);
        
        uint256 index = indexs[msg.sender];
        if (index == 0) {
            require(!strings.equal(code, ""), "code error");
            register(code);
            index = indexs[msg.sender];
        }

        Investor storage self = investors[index];
        investValue(self, msg.value);
    }

    function investValue(Investor storage self, uint256 value) internal {
        _beforeUpdate();
        
        self.value = self.value.add(value.mul(3));
        if (self.parentId > 0) {
            Investor storage current = self;

            uint256 height = 0;
            while (current.parentId != 0 && height < levels) {
                current = investors[current.parentId];
                if(current.achievements.length == height) {
                     current.achievements.push(value);
                } else {
                     current.achievements[height] = current.achievements[height].add(value);
                }
                height++;
            }
        }
        
        totalShare = totalShare.add(value.mul(3));
    }

    function balanceOfPool() internal view returns (uint256) {
        return sero_balanceOf(SERO_CURRENCY).sub(msg.value).sub(cash);
    }
}



