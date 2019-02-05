--
--[[ Market Manager ]]--
--
local Market_Manager = ZO_CallbackObject:Subclass()

function Market_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function Market_Manager:Initialize()
    self:InitializeEvents()
    self:InitializePlatformErrors()
end

function Market_Manager:InitializeEvents()
    local function OnMarketStateUpdated(eventId, ...)
        self:FireCallbacks("OnMarketStateUpdated", ...)
    end

    local function OnMarketPurchaseResult(eventId, ...)
        self:FireCallbacks("OnMarketPurchaseResult", ...)
    end

    local function OnMarketSearchResultsReady(eventId, ...)
        self:FireCallbacks("OnMarketSearchResultsReady", ...)
    end

    local function OnMarketSearchResultsCanceled(eventId, ...)
        self:FireCallbacks("OnMarketSearchResultsCanceled", ...)
    end

    local function OnCollectiblesUnlockStateChanged()
        self:FireCallbacks("OnCollectiblesUnlockStateChanged")
    end

    local function OnShowMarketProduct(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowMarketProduct(...)
    end

    local function OnShowMarketAndSearch(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowMarketAndSearch(...)
    end

    local function OnRequestPurchaseMarketProduct(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnRequestPurchaseMarketProduct(...)
    end

    local function OnShowBuyCrownsDialog(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowBuyCrownsDialog()
    end

    local function OnShowEsoPlusPage(eventId)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowEsoPlusPage()
    end

    local function OnShowChapterUpgrade(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowChapterUpgrade(...)
    end

    local function OnEsoPlusSubscriptionStatusChanged(eventId, ...)
        self:FireCallbacks("OnEsoPlusSubscriptionStatusChanged", ...)
    end

    local function OnRequestCrownGemTutorial(eventId, ...)
        SYSTEMS:GetObject(ZO_MARKET_NAME):TriggerCrownGemTutorial(...)
    end

    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_STATE_UPDATED, OnMarketStateUpdated)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PURCHASE_RESULT, OnMarketPurchaseResult)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PRODUCT_SEARCH_RESULTS_READY, OnMarketSearchResultsReady)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_PRODUCT_SEARCH_RESULTS_CANCELED, OnMarketSearchResultsCanceled)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED, OnCollectiblesUnlockStateChanged)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_MARKET_PRODUCT, OnShowMarketProduct)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_MARKET_AND_SEARCH, OnShowMarketAndSearch)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_REQUEST_PURCHASE_MARKET_PRODUCT, OnRequestPurchaseMarketProduct)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_BUY_CROWNS_DIALOG, OnShowBuyCrownsDialog)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_ESO_PLUS_PAGE, OnShowEsoPlusPage)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_MARKET_SHOW_CHAPTER_UPGRADE, OnShowChapterUpgrade)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, OnEsoPlusSubscriptionStatusChanged)
    EVENT_MANAGER:RegisterForEvent(ZO_MARKET_NAME, EVENT_REQUEST_CROWN_GEM_TUTORIAL, OnRequestCrownGemTutorial)
end

function Market_Manager:RequestOpenMarket()
    OpenMarket(MARKET_DISPLAY_GROUP_CROWN_STORE)
end

function Market_Manager:InitializePlatformErrors()
    local consoleStoreName
    local platformServiceType = GetPlatformServiceType()

    if platformServiceType == PLATFORM_SERVICE_TYPE_PSN then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_PLAYSTATION_STORE)
    elseif platformServiceType == PLATFORM_SERVICE_TYPE_XBL then
        consoleStoreName = GetString(SI_GAMEPAD_MARKET_XBOX_STORE)
    elseif platformServiceType == PLATFORM_SERVICE_TYPE_STEAM then
        self.insufficientFundsMainText = zo_strformat(SI_MARKET_INSUFFICIENT_FUNDS_TEXT_STEAM, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS))
    else -- _ZOS and _DMM
        self.insufficientFundsMainText = zo_strformat(SI_MARKET_INSUFFICIENT_FUNDS_TEXT_WITH_LINK, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS), GetString(SI_MARKET_INSUFFICIENT_FUNDS_LINK_TEXT))
    end

    if consoleStoreName then -- PS4/XBox insufficient crowns and buy crowns dialog data
        self.insufficientFundsMainText = zo_strformat(SI_GAMEPAD_MARKET_INSUFFICIENT_FUNDS_TEXT_CONSOLE_LABEL, ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_CROWNS), consoleStoreName)
    end
end

function Market_Manager:AddMarketProductPurchaseWarningStringsToTable(marketProductData, stringTable)
    if marketProductData:HasSubscriptionUnlockedAttachments() then
        local displayName = marketProductData:GetDisplayName()
        table.insert(stringTable, zo_strformat(SI_MARKET_BUNDLE_PARTS_UNLOCKED_TEXT, displayName))
    end

    if marketProductData:HasBeenPartiallyPurchased() then
        table.insert(stringTable, GetString(SI_MARKET_BUNDLE_PARTS_OWNED_TEXT))
    end
end

do
    internalassert(MARKET_PURCHASE_RESULT_MAX_VALUE == 28, "Update market error flow to handle new purchase result")
    local IS_SIMPLE_MARKET_PURCHASE_ERROR = 
    {
        [MARKET_PURCHASE_RESULT_ALREADY_COMPLETED_INSTANT_UNLOCK] = true,
        [MARKET_PURCHASE_RESULT_NOT_ENOUGH_CROWN_GEMS] = true,
        [MARKET_PURCHASE_RESULT_COLLECTIBLE_ALREADY] = true,
        [MARKET_PURCHASE_RESULT_REQUIRES_ESO_PLUS] = true,
        [MARKET_PURCHASE_RESULT_EXCEEDS_CURRENCY_CAP] = true,
    }
    function Market_Manager:GetMarketProductPurchaseErrorInfo(marketProductData)
        local expectedPurchaseResult = marketProductData:CouldPurchase()

        local displayName = marketProductData:GetDisplayName()
        local titleString = displayName
        local errorStrings = {}
        local allowContinue = true

        self:AddMarketProductPurchaseWarningStringsToTable(marketProductData, errorStrings)

        if IS_SIMPLE_MARKET_PURCHASE_ERROR[expectedPurchaseResult] then
            allowContinue = false
            table.insert(errorStrings, zo_strformat(SI_MARKET_UNABLE_TO_PURCHASE_TEXT, GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult)))
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
            allowContinue = false
            table.insert(errorStrings, self.insufficientFundsMainText)
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_ROOM then
            local slotsRequired = marketProductData:GetSpaceNeededToAcquire()
            allowContinue = false
            table.insert(errorStrings, zo_strformat(SI_MARKET_INVENTORY_FULL_TEXT, slotsRequired))
        elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_PRODUCT_ALREADY_IN_GIFT_INVENTORY then
            allowContinue = false
            table.insert(errorStrings, zo_strformat(SI_MARKET_PURCHASE_ALREADY_HAVE_GIFT_TEXT, ZO_SELECTED_TEXT:Colorize(displayName)))
        end

        local mainText = table.concat(errorStrings, "\n\n")

        local dialogParams = {
                                titleParams = { titleString },
                                mainTextParams = { mainText }
                             }
        local hasErrors = #errorStrings > 0

        return hasErrors, dialogParams, allowContinue, expectedPurchaseResult
    end
end

function Market_Manager:GetMarketProductGiftErrorInfo(marketProductData)
    local expectedPurchaseResult = marketProductData:CouldGift()

    local displayName = marketProductData:GetDisplayName()
    local titleString = displayName
    local errorStrings = {}
    local allowContinue = true

    if expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
        allowContinue = false
        table.insert(errorStrings, self.insufficientFundsMainText)
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_CROWN_GEMS then
        allowContinue = false
        table.insert(errorStrings, zo_strformat(SI_MARKET_UNABLE_TO_PURCHASE_TEXT, GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult)))
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_NOT_ALLOWED then
        allowContinue = false
        titleString = GetString(SI_MARKET_GIFTING_LOCKED_TITLE)
        table.insert(errorStrings, GetString(SI_MARKET_GIFTING_ACCOUNT_LOCKED_TEXT))
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_LOCKED then
        allowContinue = false
        titleString = GetString(SI_MARKET_GIFTING_LOCKED_TITLE)
        table.insert(errorStrings, GetString(SI_MARKET_GIFTING_SERVER_LOCKED_TEXT))
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_PRODUCT_ALREADY_IN_GIFT_INVENTORY then
        allowContinue = false
        table.insert(errorStrings, zo_strformat(SI_MARKET_GIFTING_ALREADY_HAVE_GIFT_TEXT, ZO_SELECTED_TEXT:Colorize(displayName)))
    end

    local dialogParams = {
                            titleParams = { titleString },
                            mainTextParams = { table.concat(errorStrings, "\n\n") }
                         }
    local hasErrors = #errorStrings > 0

    return hasErrors, dialogParams, allowContinue, expectedPurchaseResult
end

function Market_Manager:UpdateFreeTrialProduct()
    self.hasFreeTrialProduct = false
    -- check if there is an active eso plus product, but only grab the first one
    local productId, presentationIndex = GetActiveMarketProductListingsForEsoPlus(MARKET_DISPLAY_GROUP_CROWN_STORE)
    if productId ~= nil and productId > 0 then
        self.freeTrialMarketProductData = ZO_MarketProductData:New(productId, presentationIndex)
        local costAfterDiscount = select(3, self.freeTrialMarketProductData:GetMarketProductPricingByPresentation())
        self.hasFreeTrialProduct = costAfterDiscount and costAfterDiscount == 0 or false
    else
        self.freeTrialMarketProductData = nil
    end
end

function Market_Manager:HasFreeTrialProduct()
    return self.hasFreeTrialProduct
end

function Market_Manager:ShouldShowFreeTrial()
    return self:HasFreeTrialProduct() and not IsESOPlusSubscriber()
end

function Market_Manager:GetFreeTrialProductData()
    return self.freeTrialMarketProductData
end

do
    local freeTrialColor = GetItemQualityColor(ITEM_QUALITY_LEGENDARY)
    local function UpdateEsoPlusFreeTrialStatusText(productData)
        -- it's possible to end up in a state where there is no active
        -- free trial market product, but the player still is on a free trial
        -- in which case the trial is either over or we don't know then it ends
        local remainingTime = 0
        if productData then
            remainingTime = productData:GetLTOTimeLeftInSeconds()
        end
        local formattedRemainingTime = ZO_FormatTimeLargestTwo(remainingTime, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
        local statusText = zo_strformat(SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_FREE_TRIAL, formattedRemainingTime)
        return freeTrialColor:Colorize(statusText)
    end

    function Market_Manager:GetEsoPlusStatusText()
        local statusText
        local generateTextFunction
        if IsOnESOPlusFreeTrial() then
            generateTextFunction = function() return UpdateEsoPlusFreeTrialStatusText(self.freeTrialMarketProductData) end
            statusText = generateTextFunction()
        elseif IsESOPlusSubscriber() then
            statusText = GetString(SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_ACTIVE)
            generateTextFunction = nil
        else
            statusText = GetString(SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_NOT_ACTIVE)
            generateTextFunction = nil
        end

        return statusText, generateTextFunction
    end
end

ZO_MARKET_MANAGER = Market_Manager:New()