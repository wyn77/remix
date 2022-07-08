pragma solidity ^0.6.0;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
 abstract   contract  ERC20Interface {
    function  totalSupply()virtual public  view returns (uint);
    function balanceOf(address tokenOwner) virtual public  view returns (uint balance);
    function allowance(address tokenOwner, address spender)virtual public  view returns (uint remaining);
    function transfer(address to, uint tokens)virtual public  returns (bool success);
    function approve(address spender, uint tokens) virtual public  returns (bool success);
    function transferFrom(address from, address to, uint tokens)virtual public   returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract PETH {
     function GetUserInfo(address user) virtual public view returns (bool ,uint256,address,uint256,uint256,uint256,uint256);
}
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract  contract  ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public ;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MFS_Stacking is  Owned {

    event EVENT_REGISTER(address indexed user,address referer);
    event EVENT_STACK(address indexed user, uint period_id, uint tokens);
    event EVENT_RECEIVE(address indexed user, uint period_id,uint tokens);
    event EVENT_UNSTACK(address indexed user, uint period_id, uint tokens);

    struct  User{
        bool Registered;
        address User_Address;
        address Referer_Address;
        uint Stacking_Amount;
        
        uint256 [8] Token_Amounts;
        uint Stacking_Block_Number_Start;
        uint Stacking_Operation_Block_Stamp;
        uint256 [8] Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128;
        
        uint256 [8] Contributed_Amounts;
        uint256 [8] Stacking_Amounts;
        uint256 [8] Block_of_Last_Stack;
        
    }
    
    uint256 [8] public m_Block_weight_of_Stack_Options;
    uint256 public m_Block_weight_of_Total_Stack_Option;
    uint256 [8] public m_Block_Span_of_Stack_Options;
    
    using SafeMath for uint;
    //addr for user updater
    address public m_Updater_Address;
    //addr for user relationship
    //address public m_Referer_Info_Address;
    // addr for stacking token
    address public m_Stacking_Address;
    // addr for target token 
    address public m_Token_Address;

    //game's block span
    uint public m_Stacking_Block_Number_Start;
    uint public m_Stacking_Block_Number_Stop;
    
    // total amount of stacking
    uint256 public m_Total_Stacking; 
    // total user number
    uint256 public m_User_Count;


    uint256 public m_BlockNum_Of_Last_Update=0;
    //uint256 [8] public m_Sum_of_Weighted_Stacking_of_Stack_Options;
    
    uint256 [8]public m_Sum_Of_Weighted_Stacking_Reciprocal_e128;
    uint256 public m_FIX_POINT=( 1*2**128);
    
    // indicate whether game is paused true=pause false=play
    bool m_Game_Pause;
    //if user unstacking within a span of blocks take 10% receiving token for fee;  
    uint256 m_Punishment_Span;
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    modifier NotGamePause()
    {
        require(m_Game_Pause!=true);
        _;
    }
    modifier OnlyRegistered()
    {
        require(m_User_Map[msg.sender].Registered==true);
        _;
    }
    mapping(address => User) public  m_User_Map;
    constructor() public {
        m_Total_Stacking=1e18;
        m_Game_Pause=false;
        m_User_Count=1;
        m_Punishment_Span=1;
        m_BlockNum_Of_Last_Update=block.number;
        m_Stacking_Block_Number_Start=block.number;
        m_Stacking_Block_Number_Stop=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        
        for(uint i=0;i<8;i++)
        {
        //m_Sum_of_Weighted_Stacking_of_Stack_Options[i]=1e18;
        }
    }

    function Set_Token_Address( address stacking,address token) public onlyOwner{
        m_Stacking_Address=stacking;
        m_Token_Address=token;
    }
 

    function Set_Updater_Address( address addr) public onlyOwner{
        m_Updater_Address=addr;
    }

    function Set_Punishment_Span( uint span) public onlyOwner{
        m_Punishment_Span=span;
    }
    function Pause( ) public onlyOwner{
       m_Game_Pause=true;
       m_Stacking_Block_Number_Stop=block.number;
    }
    function Resume( ) public onlyOwner{
       m_Game_Pause=false;
       m_Stacking_Block_Number_Stop=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    function Start_At(uint block_number) public onlyOwner{
            if(block_number==0)
            {
                uint number = block.number;
                m_Stacking_Block_Number_Start=number;
            }else
            {
                m_Stacking_Block_Number_Start=block_number;
            }
    }
    function Stop_At(uint block_number) public onlyOwner{
        if(block_number==0)
        {
            uint number = block.number;
             m_Stacking_Block_Number_Stop=number;
        }else
        {
             m_Stacking_Block_Number_Stop=block_number;
        }
    }
    function GetRefererAddress(address user )private returns(address)
    {
        return(m_User_Map[user].Referer_Address);
    }
    function Get_User_Info(address user ) public view returns(bool ,address, address, uint,uint)
    {
        return
        (
        m_User_Map[user]. Registered,
        m_User_Map[user]. User_Address,
        m_User_Map[user]. Referer_Address,
        m_User_Map[user]. Stacking_Amount,
        m_User_Map[user]. Stacking_Operation_Block_Stamp
        );
    }
     function Get_User_Stackings(address user ) public view returns(  uint[8] memory)
     {
          return
        (
          m_User_Map[user]. Stacking_Amounts 
        );
     }
    function Get_User_Contributions(address user ) public view returns(  uint[8] memory)
     {
          return
        (
          m_User_Map[user].Contributed_Amounts
        );
     }
     
    function Get_User_Block_of_Last_Stack(address user ) public view returns(  uint[8] memory)
     {
          return
        (
          m_User_Map[user]. Block_of_Last_Stack 
        );
     }
     
    function Get_Game_Info() public view returns(uint256,uint256,uint256 )
    {
        return(
            m_Total_Stacking,m_User_Count,m_Punishment_Span
        );
    }
    function Do_Set_Referer(address user,address referer) public {
        require(msg.sender==m_Updater_Address,"DISQUALIFIED");
        m_User_Map[user].Referer_Address=referer; 
    }
    function Do_Set_Referers(address[] memory user,address[] memory referer) public {
        require(msg.sender==m_Updater_Address,"DISQUALIFIED");
        require(user.length==referer.length,"INVALID DATA");
        for(uint i =0 ;i< user.length;i++)
        {
        m_User_Map[user[i]].Referer_Address=referer[i]; 
        }
    }
    function Do_Registering(address referer) public  NotGamePause returns(bool){
        // initialize user data
        Update_Global_Data();        
        
        require( referer != address(0),"REFERER ERROR");
        require( m_User_Map[msg.sender].Registered==false,"USER EXIST");
        //require( m_User_Map[referer].Registered==true,"REFERER NOT EXIST");
        
        m_User_Map[msg.sender].Registered=true;
        m_User_Map[msg.sender].User_Address=msg.sender;
        if(m_User_Map[msg.sender].Referer_Address== address(0))
        {
            m_User_Map[msg.sender].Referer_Address=referer; 
        }
        m_User_Map[msg.sender].Stacking_Block_Number_Start= block.number;
        m_User_Map[msg.sender].Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128=m_Sum_Of_Weighted_Stacking_Reciprocal_e128;
        
        //set block_num of stack
        for(uint i=0;i<8;i++)
        {
        m_User_Map[msg.sender].Block_of_Last_Stack[i]=block.number;
        }
        emit EVENT_REGISTER(msg.sender,m_User_Map[msg.sender].Referer_Address);
        return true;
    }
    function Do_Stacking(uint period_id,uint stacking_amount) public OnlyRegistered  NotGamePause returns(bool){
           uint256 exa_amount=0;
           uint256 old_balance= ERC20Interface(m_Stacking_Address).balanceOf(address(this));
            //transfer from user to contract
            bool res=false;
            res=ERC20Interface(m_Stacking_Address).transferFrom(msg.sender, address(this),stacking_amount);
            if(res ==false)
            {
                //if failed revert transaction;
                 revert();
            }
            uint256 new_balance= ERC20Interface(m_Stacking_Address).balanceOf(address(this));
            exa_amount=new_balance.sub(old_balance);
            
            uint256 old_stacking_amount=m_User_Map[msg.sender].Stacking_Amount;

            // update token value in pass;
            Update_Global_Data();
            Update_User(msg.sender);
            m_User_Map[msg.sender].Stacking_Operation_Block_Stamp=block.number;
            m_User_Map[msg.sender].Block_of_Last_Stack[period_id]=block.number;
            
            
            // update user and contract data
            m_Total_Stacking=m_Total_Stacking.add(exa_amount);
            m_User_Map[msg.sender].Stacking_Amount= m_User_Map[msg.sender].Stacking_Amount+exa_amount;        
            m_User_Map[msg.sender].Stacking_Amounts[period_id]= m_User_Map[msg.sender].Stacking_Amounts[period_id]+exa_amount;
          
          
             //------------------------------------------------------------
            // add contribute
            //------------------------------------------------------------
            address referer_address=GetRefererAddress(msg.sender); 
            if(referer_address!=address(0) && m_User_Map[referer_address].Registered==true )
            {
                Update_User(referer_address);          
            }
            if(referer_address!=address(0))
            {
                m_User_Map[referer_address].Contributed_Amounts[period_id]=m_User_Map[referer_address].Contributed_Amounts[period_id].add(exa_amount/5);
            }

            //------------------------------------------------------------
            //  add contribute
            //------------------------------------------------------------
            referer_address=GetRefererAddress(referer_address); 
            if(referer_address!=address(0) && m_User_Map[referer_address].Registered==true)
            {
                Update_User(referer_address);           
            }
            if(referer_address!=address(0))
            {
                 m_User_Map[referer_address].Contributed_Amounts[period_id]=m_User_Map[referer_address].Contributed_Amounts[period_id].add(exa_amount/10);
            }

                      
            if(old_stacking_amount<15e16 && m_User_Map[msg.sender].Stacking_Amount>=15e16  )
            {
                m_User_Count=m_User_Count+1;
            }

            emit EVENT_STACK(msg.sender,period_id, exa_amount);
            return true;
    }
    function Do_Receiving(uint period_id) public  OnlyRegistered  NotGamePause returns(bool) {

        Update_Global_Data();
        Update_User(msg.sender);
        bool res=false;

        res=ERC20Interface(m_Token_Address).transfer(msg.sender,m_User_Map[msg.sender].Token_Amounts[period_id]);
        
        if(res ==false)
        {
            revert();
        }
    

        emit EVENT_RECEIVE(msg.sender,period_id, m_User_Map[msg.sender].Token_Amounts[period_id]);
        
        m_User_Map[msg.sender].Token_Amounts[period_id]=0;
        return true;
    }

    function Do_Unstacking(uint period_id ,uint stacking_amount) public  OnlyRegistered   returns(bool)  {
            
            uint bn=block.number;
            uint256 block_span=bn.sub(m_User_Map[msg.sender].Block_of_Last_Stack[period_id]);
            require(block_span>= m_Block_Span_of_Stack_Options[period_id]);
            //check balance
            require( m_User_Map[msg.sender].Stacking_Amounts[period_id]>=stacking_amount);
            
            Update_Global_Data();
            Update_User(msg.sender);
            uint256 old_stacking_amount=m_User_Map[msg.sender].Stacking_Amount;
            bool res=false;
            res=ERC20Interface(m_Stacking_Address).transfer(msg.sender,stacking_amount);
            if(res ==false)
            {
                 revert();
            }
            m_User_Map[msg.sender].Stacking_Amounts[period_id]=m_User_Map[msg.sender].Stacking_Amounts[period_id].sub(stacking_amount);
            m_Total_Stacking=m_Total_Stacking.sub(stacking_amount);
            
            //------------------------------------------------------------
            // sub contribute
            //------------------------------------------------------------
            address referer_address=GetRefererAddress(msg.sender); 
            if(referer_address!=address(0) && m_User_Map[referer_address].Registered==true)
            {
                Update_User(referer_address);
            }
            if(referer_address!=address(0))
            {
                if(m_User_Map[referer_address].Contributed_Amounts[period_id]>=(stacking_amount/5))
                {
                    m_User_Map[referer_address].Contributed_Amounts[period_id]=m_User_Map[referer_address].Contributed_Amounts[period_id]-(stacking_amount/5);
                }else
                {
                    m_User_Map[referer_address].Contributed_Amounts[period_id]=0;
                }
            }
            //------------------------------------------------------------
            //  sub contribute
            //------------------------------------------------------------
            referer_address=GetRefererAddress(referer_address); 
            if(referer_address!=address(0) && m_User_Map[referer_address].Registered==true)
            {
                Update_User(referer_address);
            }
            if(referer_address!=address(0))
            {
                if(m_User_Map[referer_address].Contributed_Amounts[period_id]>=(stacking_amount/10))
                {
                    m_User_Map[referer_address].Contributed_Amounts[period_id]=m_User_Map[referer_address].Contributed_Amounts[period_id]-(stacking_amount/10);
                }else
                {
                    m_User_Map[referer_address].Contributed_Amounts[period_id]=0;
                }
            }
            
            if(old_stacking_amount>=15e16 && m_User_Map[msg.sender].Stacking_Amount<15e16 )
            {
                m_User_Count=m_User_Count-1;
            }
            emit EVENT_UNSTACK(msg.sender,period_id, stacking_amount);
            return true;
    }
   function Do_Game_Update() public    returns(bool){
        require(msg.sender==m_Updater_Address,"DISQUALIFIED");
        Update_Global_Data();
         //Update_User(user,false);
        return true;
    }
    function Do_Update_User(address user) public    returns(bool){
        require(msg.sender==m_Updater_Address,"DISQUALIFIED");
        Update_Global_Data();
        require(m_User_Map[user].Registered==true);
        Update_User(user);
        return true;
    }
    function Update_Global_Data() private
    {
         uint block_num_clamp=block.number;
        if(block_num_clamp>m_Stacking_Block_Number_Stop)
        {
            block_num_clamp=m_Stacking_Block_Number_Stop;
        }
        if(block_num_clamp<m_Stacking_Block_Number_Start)
        {
            block_num_clamp=m_Stacking_Block_Number_Start;
        }

        uint256 block_span=block_num_clamp-m_BlockNum_Of_Last_Update;
        if(block_span==0)
        {
            //m_TotalStackingOfLastUpdate=stacking_amount+m_TotalStackingOfLastUpdate;
        }else{
            
            for (uint i =0;i<8;i++)
            {
                
            uint256 delta=  m_FIX_POINT;
            uint256 t_total_stacking=m_Total_Stacking;
            delta=delta/t_total_stacking;
            delta=delta*block_span* m_Block_weight_of_Stack_Options[i] ;
            m_Sum_Of_Weighted_Stacking_Reciprocal_e128[i]=m_Sum_Of_Weighted_Stacking_Reciprocal_e128[i]+delta;
            }
        }
        m_BlockNum_Of_Last_Update=block_num_clamp;
    }
    function Do_Update() public  OnlyRegistered  NotGamePause returns(bool){
        Update_Global_Data();
        Update_User(msg.sender);
        return true;
    }
    function Update_User(address user) private
    {   
        if(m_User_Map[user].Registered==false)
        {
            return;
        }
        uint block_num_clamp=block.number;
        if(block_num_clamp>m_Stacking_Block_Number_Stop)
        {
            block_num_clamp=m_Stacking_Block_Number_Stop;
        }
            m_User_Map[user].User_Address=user;
            //// check user's block number which should be lower than  current number and greater than 0;
            if(m_User_Map[user].Stacking_Block_Number_Start<=m_Stacking_Block_Number_Start)
            {
                m_User_Map[user].Stacking_Block_Number_Start= block_num_clamp;
            }
            if(m_User_Map[user].Stacking_Block_Number_Start> block_num_clamp)
            {
                m_User_Map[user].Stacking_Block_Number_Start= block_num_clamp;
            }
            if(m_User_Map[user].Stacking_Block_Number_Start>= m_Stacking_Block_Number_Stop )
            {
                m_User_Map[user].Stacking_Block_Number_Start=m_Stacking_Block_Number_Stop;
            }

////BASE///////////////////////////////////////////////////////////////
        
        uint sum_of_quantity=0;
        for (uint i =0;i<8;i++)
        {
            
            uint t_fixed_point=(2**2);
            uint quantity=m_Sum_Of_Weighted_Stacking_Reciprocal_e128[i].sub( m_User_Map[user].Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128[i]);
            quantity=quantity/t_fixed_point;
            quantity=(m_User_Map[user].Stacking_Amounts[i]+m_User_Map[user].Contributed_Amounts[i])*quantity;
            
            //quantity=quantity*m_Block_weight_of_Stack_Options[i];
            quantity=quantity/1;//m_Block_weight_of_Total_Stack_Option;
            
            quantity=quantity/( m_FIX_POINT);
            quantity=quantity*t_fixed_point;
            
            m_User_Map[user].Token_Amounts[i]= m_User_Map[user].Token_Amounts[i].add(quantity);
            sum_of_quantity=sum_of_quantity+quantity;
        }
       


////Update Block Number////////////////////////////////////////////////////////////       
        m_User_Map[user].Stacking_Block_Number_Start= block_num_clamp;
////Update Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128////////////////////////////////////////////////////////////       
        m_User_Map[user].Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128= m_Sum_Of_Weighted_Stacking_Reciprocal_e128;
    
    
    }
    


    function Take_Token(address token_address,uint token_amount) public onlyOwner{
           ERC20Interface(token_address).transfer(msg.sender,token_amount);
    }
    
    function TakeFee10(uint token_amount) private pure returns (uint) {
            uint res=token_amount;
            res=res*9;
            res=res/10;
            return res;
    }
    function ViewReceiving(address user) public view  returns (uint256[8]memory) {
       ////Get how many blocks between last operation and current block///
        uint block_num_clamp=block.number;
        if(block_num_clamp>m_Stacking_Block_Number_Stop)
        {
            block_num_clamp=m_Stacking_Block_Number_Stop;
        }
        if(block_num_clamp<m_Stacking_Block_Number_Start)
        {
            block_num_clamp=m_Stacking_Block_Number_Start;
        }

        uint256 block_span=block_num_clamp-m_BlockNum_Of_Last_Update;
        uint256 [8] memory t_Sum_of_Weighted_Stacking_of_Stack_Options=m_Sum_Of_Weighted_Stacking_Reciprocal_e128;
        if(block_span==0)
        {
            //m_TotalStackingOfLastUpdate=stacking_amount+m_TotalStackingOfLastUpdate;
        }else{
            for (uint i =0;i<8;i++)
            {
                 
            uint256 delta=  m_FIX_POINT;
            uint256 t_total_stacking=m_Total_Stacking;
            delta=delta/t_total_stacking;
            delta=delta*block_span*m_Block_weight_of_Stack_Options[i] ;
            t_Sum_of_Weighted_Stacking_of_Stack_Options[i]=m_Sum_Of_Weighted_Stacking_Reciprocal_e128[i]+delta;
            
                
            }
            
        }
////BASE///////////////////////////////////////////////////////////////
        
        
        uint256[8] memory t_Token_Amounts=m_User_Map[user].Token_Amounts;
        uint256 sum_of_quantity=0;
        for (uint i =0;i<8;i++)
        {
            
             uint t_fixed_point=(2**1);
            uint quantity=t_Sum_of_Weighted_Stacking_of_Stack_Options[i].sub( m_User_Map[user].Last_Updated_Sum_Of_Weighted_Stacking_Reciprocal_e128[i]);
            quantity=quantity/t_fixed_point;
            quantity=(m_User_Map[user].Stacking_Amounts[i]+m_User_Map[user].Contributed_Amounts[i])*quantity;
            
            //quantity=quantity*m_Block_weight_of_Stack_Options[i];
            quantity=quantity/1;//m_Block_weight_of_Total_Stack_Option;
            
            quantity=quantity/( m_FIX_POINT);
            quantity=quantity*t_fixed_point;
            
            t_Token_Amounts[i]=t_Token_Amounts[i].add(quantity);
            sum_of_quantity=sum_of_quantity+quantity;
        }
 /////////////////////////////////////////////////////////////////////////////   
    
        return t_Token_Amounts;
    }


    
    function Set_Block_Weight(uint period_id, uint256 block_weight)public onlyOwner
    {
        Update_Global_Data();
        m_Block_weight_of_Stack_Options[period_id]=block_weight;
        m_Block_weight_of_Total_Stack_Option=0;
        for(uint i=0;i<8;i++)
        {
            m_Block_weight_of_Total_Stack_Option+=m_Block_weight_of_Stack_Options[i];
        }
    }

    function Set_Period_Span(uint period_id, uint256 block_span)public onlyOwner
    {
        m_Block_Span_of_Stack_Options [period_id]=block_span;
    }
    fallback() external payable {}
    receive() external payable { 
   
    }
    function Call_Function(address addr,uint256 value ,bytes memory data) public  onlyOwner {
      addr.call.value(value)(data);
    }
}
