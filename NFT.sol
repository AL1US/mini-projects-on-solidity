
    function finishAuctionNFT(uint256 _index) public {
        structAuctionNFT storage auc = auctionNFT[_index];
        structBet storage lastBet = betNFT[_index];

        require(block.timestamp >= auc.timeEND, "Auction is not finished");
        require(auc.ownerAuction != address(0), "Auction does not exist");
        
        // Получатель
        address recipient;
        if (lastBet.price == 0) {
            // Нет ставок, возвращаем NFT владельцу
            _safeTransferFrom(address(this), auc.ownerAuction, auc.idNFT, auc.amount, "");
            recipient = auc.ownerAuction;
        } else {
            // Покупатель получает NFT
            _safeTransferFrom(address(this), lastBet.owner, auc.idNFT, auc.amount, "");
            transfer(auc.ownerAuction, lastBet.price);
            recipient = lastBet.owner;
        }

        // Обновляем мапинг у получателя
        structNFT memory nftData = allNFT[auc.idNFT];
        if (NFT[recipient][auc.idNFT].amount > 0) {
            NFT[recipient][auc.idNFT].amount += auc.amount;
        } else {
            NFT[recipient][auc.idNFT] = nftData;
            NFT[recipient][auc.idNFT].amount = auc.amount;
        }

        // Чистим данные
        delete auctionNFT[_index];
        delete betNFT[_index];
    }
