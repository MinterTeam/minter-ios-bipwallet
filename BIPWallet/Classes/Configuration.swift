//
//  Configuration.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 21/03/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

let blocksUntilDelegatedBalanceUpdate = 120

struct Configuration {

	init() {}

	var environment: Environment = {
		if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
			if configuration.range(of: "dev") != nil {
				return Environment.dev
			}
		}
		return Environment.prod
	}()
}

enum Environment: String {

	case dev
	case prod

  var helpURL: String {
    switch self {
    case .dev: return "https://help.minter.network"
    case .prod: return "https://help.minter.network"
    }
  }

  var telegramChannelURL: String {
    switch self {
    case .dev: return "tg://resolve?domain=MinterTeam"
    case .prod: return "tg://resolve?domain=MinterTeam"
    }
  }

  var telegramChannelURLRU: String {
    switch self {
    case .dev: return "tg://resolve?domain=MinterNetwork"
    case .prod: return "tg://resolve?domain=MinterNetwork"
    }
  }

  var telegramChannelWEBURL: String {
    switch self {
    case .dev: return "https://t.me/MinterTeam"
    case .prod: return "https://t.me/MinterTeam"
    }
  }

  var telegramChannelWEBURLRU: String {
    switch self {
    case .dev: return "https://t.me/MinterNetwork"
    case .prod: return "https://t.me/MinterNetwork"
    }
  }

  var supportTelegramChannelURL: String {
    switch self {
    case .dev: return "tg://resolve?domain=MinterHelp"
    case .prod: return "tg://resolve?domain=MinterHelp"
    }
  }

  var supportTelegramChannelWEBURL: String {
    switch self {
    case .dev: return "https://t.me/MinterHelp"
    case .prod: return "https://t.me/MinterHelp"
    }
  }

	var nodeBaseURL: String {
		switch self {
		case .dev: return "https://minter-node-2.mainnet.minter.network"
		case .prod: return "https://minter-node-1.mainnet.minter.network"
		}
	}

	var explorerAPIBaseURL: String {
		switch self {
		case .dev: return "https://explorer-api.testnet.minter.network"
		case .prod: return "https://explorer-api.apps.minter.network"
		}
	}

	var explorerWebURL: String {
		switch self {
		case .dev: return "https://explorer.testnet.minter.network"
		case .prod: return "https://explorer.minter.network"
		}
	}

	var explorerWebsocketURL: String {
		switch self {
		case .dev: return "wss://explorer-rtm.testnet.minter.network/connection/websocket"
		case .prod: return "wss://explorer-rtm.apps.minter.network/connection/websocket"
		}
	}

	var testExplorerAPIBaseURL: String {
		switch self {
		case .dev: return "https://qa.explorer-api.minter.network"
		case .prod: return "https://qa.explorer-api.minter.network"
		}
	}

	var testExplorerWebURL: String {
		switch self {
		case .dev: return "https://qa.explorer.minter.network"
		case .prod: return "https://qa.explorer.minter.network"
		}
	}

	var testExplorerWebsocketURL: String {
		switch self {
		case .dev: return "wss://qa.rtm.minter.network/connection/websocket"
		case .prod: return "wss://qa.rtm.minter.network/connection/websocket"
		}
	}

	// MY Minter
	var myAPIBaseURL: String {
		switch self {
		case .dev: return "https://my.beta.minter.network"
		case .prod: return "https://my.apps.minter.network"
		}
	}

	var appstoreURLString: String {
		switch self {
		case .dev:
			return "https://itunes.apple.com/us/app/bip-wallet/id1457843214?ls=1&mt=8"
//			return "https://itunes.apple.com/us/app/bip-wallet-testnet/id1436988091?ls=1&mt=8"
		case .prod:
			return "https://itunes.apple.com/us/app/bip-wallet/id1457843214?ls=1&mt=8"
		}
	}

  var passbookAPIURLString: String {
    switch self {
    case .dev:
      return "https://testnet.passbook-api.minter.network/v1/"
    case .prod:
      return "https://passbook-api.minter.network/v1/"
    }
  }

  var passbookTypeString: String {
    switch self {
    case .dev:
      return "pass.MNT.BipWallet.pass"
    case .prod:
      return "pass.MNT.BipWallet.storeCard"
    }
  }

}
