﻿ZO_BUY_CROWNS_URL_TYPE = {urlType = APPROVED_URL_ESO_ACCOUNT_STORE}
ZO_BUY_CROWNS_FRONT_FACING_ADDRESS = {mainTextParams = {GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB)}}

ZO_BUY_SUBSCRIPTION_URL_TYPE = { urlType = APPROVED_URL_ESO_ACCOUNT_SUBSCRIPTION }
ZO_BUY_SUBSCRIPTION_FRONT_FACING_ADDRESS = {mainTextParams = { GetString(SI_ESO_PLUS_SUBSCRIPTION_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB) }}

function ZO_MarketDialogs_Shared_OpenURLByType(dialog)
    OpenURLByType(dialog.data.urlType)
end