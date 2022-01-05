-- Inofficial Bux Zero Extension for MoneyMoney
-- Author: Valentin Morlock
WebBanking {
    version = 1.00,
    url = "https://getbux.com",
    services = {"Bux Zero"},
    description = "View your Bux Zero portfolio in MoneyMoney"
}

local email
local passcode
local connection = Connection()

function SupportsBank(protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "Bux Zero"
end

function InitializeSession2(protocol, bankCode, step, credentials, interactive)
    if step == 1 then
        email = credentials[1]
        passcode = credentials[2]
    end

    if LocalStorage["token"] == nil and interactive == true and step == 1 then
        body = JSON():set({
            email = email
        }):json()

        headers = {
            ["accept-language"] = "en,",
            ["x-app-version"] = "4.7-7174",
            ["x-os-version"] = "9",
            ["content-type"] = "application/json",
            ["accept-encoding"] = "gzip",
            ["user-agent"] = "okhttp/4.9.1",
            ["Authorization"] = "Basic ODQ3MzYyMzAxMDpaTUhaM1RZT1pIVUxFRlhMUDRRQ1BIV0k1RDNWQVpNNw=="
        }

        connection:request("POST", "https://auth.getbux.com/api/3/magic-link", body, "application/json", headers)

        return {
            title = "Bux Login",
            challenge = "Bitte Magic-Link aus der Mail kopieren & eingeben",
            label = "Magic Link"
        }
    end

    if LocalStorage["token"] == nil and interactive == true and step == 2 then
        loginUrl = credentials[1]
        _, _, loginCode = loginUrl:find("^.*/(.+)$")

        if (loginCode == nil or loginCode == '') then
            error("Ungültiger Link")
        end

        body = JSON():set({
            credentials = {
                token = loginCode
            },
            type = 'magiclink'
        }):json()

        headers = {
            ["accept-language"] = "en,",
            ["x-app-version"] = "4.7-7174",
            ["x-os-version"] = "9",
            ["content-type"] = "application/json",
            ["accept-encoding"] = "gzip",
            ["user-agent"] = "okhttp/4.9.1",
            ["Authorization"] = "Basic ODQ3MzYyMzAxMzpHRFNTS1ozUU5RQ081QkNXN0RJRFhVWEE2RENSUUNNRQ=="
        }

        result =
            connection:request("POST", "https://auth.getbux.com/api/3/authorize", body, "application/json", headers)

        LocalStorage["token"] = JSON(result):dictionary()["access_token"]

        print("obtained token" .. LocalStorage["token"])

        if LocalStorage["token"] == nil then
            return LoginFailed
        end
    end

end

function ListAccounts(knownAccounts)
    local account = {
        name = "Bux Depot",
        accountNumber = email,
        currency = "EUR",
        portfolio = true,
        type = "AccountTypePortfolio"
    }

    return {account}
end

function RefreshAccount(account, since)
    headers = {
        ["accept-language"] = "en,",
        ["x-app-version"] = "4.7-7174",
        ["x-os-version"] = "9",
        ["content-type"] = "application/json",
        ["accept-encoding"] = "gzip",
        ["user-agent"] = "okhttp/4.9.1",
        ["authorization"] = "Bearer " .. LocalStorage["token"]
    }

    raw = connection:request("GET", "https://stocks.prod.getbux.com/portfolio-query/13/users/me/portfolio", nil, nil,
        headers)

    result = JSON(raw):dictionary()

    s = {}

    for k, etf in pairs(result["positions"]["ETF"]) do
        s[#s + 1] = {
            name = etf["security"]["name"],
            isin = etf["security"]["id"],
            currency = nil,
            quantity = etf["position"]["quantity"],
            amount = etf["position"]["investmentAmount"]["amount"],
            price = etf["security"]["offer"]["amount"]
        }
    end

    for k, stock in pairs(result["positions"]["EQTY"]) do
        s[#s + 1] = {
            name = stock["security"]["name"],
            isin = stock["security"]["id"],
            currency = nil,
            quantity = stock["position"]["quantity"],
            amount = stock["position"]["investmentAmount"]["amount"],
            price = stock["security"]["offer"]["amount"]
        }
    end

    return {
        securities = s
    }
end

function EndSession()
end

-- SIGNATURE: MCwCFF9M767E2kjMhBQw+bh2g7uOcLuxAhQEv9qMeeMCdnJ9blp98uBEqfwXXA==
