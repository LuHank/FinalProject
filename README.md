- Project Name: Web3 Game Station  
- Description  
  - purpose  
    - 遊戲裝備生成(單品或者整套)  
    - 提供遊戲裝備自由交易(option)  
    - 租用遊戲裝備強化角色(option)  
    - 連結元宇宙遊戲  
  - goals  
    - 提供遊戲更好體驗服務  
  - background  
    - 解決傳統遊戲交易問題  
      - 解決傳統只能在單一平台購買遊戲裝備 
      - 解決傳統只能在單一平台交易裝備 
    - 解決傳統遊戲無法提供的服務  
      - 提供閒置或者藍籌遊戲裝備可再利用  
      - 提供遊戲裝備租用服務(option)  
  
- Framework  
  - Web3 Game Station overall    
    - Auction Market  
      - create Auction Market  
      - ERC721A -  one transaction multiple NFT  
      - Combine Sell - ERC1155  
    - Rent  
      - reNFT - add update and get owner information functions  
  - Web3 Game Station 主要功能  
    - control  
      - 管理者控管  
      - 白名單控管  
      - 只允許 EOA 避免合約駭客攻擊  
      - 只有管理者才可以把平台餘額出金  
    - Auction Market  
      - 設定交易手續費  
      - 設定出金地址  
      - 創建拍賣  
      - 拍賣出價  
      - 完成拍賣  
      - 取消拍賣  
      - 平台出金  
      - 相關 get 拍賣及出價資訊  
    - Lending & Renting  
      - Lend 借出  
      - Rent 租借  
      - 更改 Lend 借出每日租金  
      - 更改 Rent 租借金額 / 期間 / 時間點  
      - 獲得所有者(lender)的所有 Lend 借出資訊  
      - 獲得租借者(renter)的所有 Rent 租借資訊  
      - 其他 Lend 及 Rent 相關 get 資訊  
  - overall flow and components interaction    
    ![](./overall-flow.png)  
  
- Development  
  - Include step-by-step instructions on how to set up and run the project.  
    - command example  
      - forge install chiru-labs/ERC721A --no-commit  
      - forge install openzeppelin/openzeppelin-contracts --no-commit  
      - deploy & set up   
        - deploy NFT contract (inclue start time to mint)   
        - deploy Resolver contract for Web3GameStation constructor  
        - deploy USDC ERC20 token contract for USDC payment  
        - set up token payment for Rent  
          resolver.setPaymentToken(1, address(usdc));  
        - deploy web3GameStation contract  
        - set up web3GameStation  
          - white list  
            web3GameStation.setSaleMerkleRoot(merkleRoot);  
            merkleProof.push(0xcf35cc271f7afbaa4ae6d57c87db8efc82e3badbbccf985b1034cff2126b3f2a);  
          - withdraw address (admin)  
          - recipient address (admin)  
        - premise  
          - user need to enough ETH  
          - user need to enough USDC to rent NFT  
      - else implementation matters  
        - need to mint after start time  
- Testing
  - Explain how to run the tests. [Nice to have] 80% or more coverage.  
    - 事前部署與設定: 參考 Development - deploy & set up  
    - test NFT mint  
      - 測試是否有在 start time 之後可以 mint  
      - 測試是否有產生相對應的 NFT 數量  
    - test Auction Market - 拍賣流程  
      - 需先 mint NFT  
      - 核准 NFT 權限給 Web3 Game Station contract  
      - 創建 Auction 掛單並檢查是否有儲存 Auction 資料以及事件是否紀錄 Create  
      - 另一人針對拍賣出價並檢查 Auction 資料是否更新以及事件是否紀錄 Bid  
      - 完成拍賣並檢查 Auction 資料是否有更新以及事件是否紀錄 complete    
      - 完成拍賣後檢查 NFT 以及 ETH 流向  
      - 創建另一個 Auction 掛單並取消然後檢查是否取消成功以及事件是否紀錄 Cancel   
      - 平台出金並檢查是否存入設定的 admin address   
    - test Rent - 租賃流程    
      - 需先 mint NFT  
      - 核准 NFT 權限給 Web3 Game Station contract  
      - 蒐集 lend function 所需要的參數陣列  
      - lender 執行 lend NFT 並檢查 NFT 是否跑到 Web3 Game Station contract  
      - 修改 lend 資料中每日租金金額並檢查 lend 資料是否更新成功    
      - renter 將 USDC token 核准給 Web3 Game Station contract  
      - 蒐集 rent function 所需要的參數陣列  
      - renter 執行 rent NFT 並檢查是否儲存 rent 資料以及是否以 USDC 支付  
      - 修改 rent 資料並檢查 lend 資料是否更新成功  
      - 測試只能由 EOA 呼叫合約  
      - lender 增加一筆 lend NFT 並檢查 OwnerLending (可列出 NFT Owner 所有 lend 詳細資料) 是否儲存成功   
  
- Usage
  - Explain how to use the project and provide examples or code snippets to demonstrate its usage.  
    - 有關 Auction Market 以及 Rent 相關功能及使用方式，可以參考 test/Web3GameStation.t.sol  
    - 若元宇宙遊戲商想要驗證使用者是否有租用使用權或者使用者欲查詢裝備是否出租，可使用以下 function 查詢。
      - getRenting  
      - getOwnerRenting  
      - getLending  
      - getOwnerLending  