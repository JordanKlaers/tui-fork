-- TweaksUI Default Profiles
-- Built-in profiles loaded from export strings
-- To add/update a profile: paste the export string in the appropriate field below
-- Profiles with empty exportString values won't appear in the list

local ADDON_NAME, TweaksUI = ...

TweaksUI.DefaultProfiles = {}
local DefaultProfiles = TweaksUI.DefaultProfiles

-- ============================================================================
-- DEFAULT PROFILE DEFINITIONS
-- Paste your export strings between the [[ ]] markers for each profile
-- ============================================================================

local PROFILE_DEFINITIONS = {
    -- ========================================================================
    -- ROLE PROFILES
    -- ========================================================================
    
    ["Tank"] = {
        name = "Tank",
        description = "Optimized for tanking with defensive cooldown tracking",
        icon = "Interface\\Icons\\Ability_Defend",
        iconCoords = nil,
        category = "role",
        order = 1,
        -- PASTE TANK EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
    
    ["Healer"] = {
        name = "Healer",
        description = "Optimized for healing with group-focused visibility",
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        iconCoords = nil,
        category = "role",
        order = 2,
        -- PASTE HEALER EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
    
    ["Melee DPS"] = {
        name = "Melee DPS",
        description = "Optimized for melee DPS with uptime tracking",
        icon = "Interface\\Icons\\Ability_DualWield",
        iconCoords = nil,
        category = "role",
        order = 3,
        -- PASTE MELEE DPS EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
    
    ["Ranged DPS"] = {
        name = "Ranged DPS",
        description = "Optimized for ranged DPS with proc tracking",
        icon = "Interface\\Icons\\Ability_Hunter_SteadyShot",
        iconCoords = nil,
        category = "role",
        order = 4,
        -- PASTE RANGED DPS EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
    
    -- ========================================================================
    -- STYLE PROFILES
    -- ========================================================================
    
    ["Basic"] = {
        name = "Basic",
        description = "Balanced setup suitable for all content",
        icon = "Interface\\Icons\\Spell_Nature_Sleep",
        iconCoords = nil,
        category = "style",
        order = 10,
        -- PASTE BASIC EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[TUI150:CGGOA0B:S3vAxTnYA6)k54pN4J2x4BaHKWmHegGUZ9oDFp5iSfGMiB5RSme6mZ)959P2lj5fcqAiXDFs3XvjvQwER36D9P(2GppjVjBWoFBq24XvthSZGZUjp7lZ)Tdh8YbJUkR(dztYPspTy6Ln3uHcRZZAYhpyh34OyVu)KW4xoyCEzt2bthvng10uVi)LdONRCc9Q7vx91IlZQP3Do9Y5tFxEXLx1qnqqGJSSpvmU5Qb74fgrfTO40rzL0N1zyKFk(NKWO0GK0xo46865fS(PBOZG)VxoiBud979YQ3VAAtwX086JRMxGYMtJk6boFXfx8o6dwIpkkJ9kxtTo93MplFuZjz0JZF4rlM3unzxwXVRBrFIxu1SSrfn3Y)X8SMf1OfOof73xvDJ4Vv8x4R8)rfMpn78sm1GN4QIX5NvNn6l51d25ISY50KvX0)g6vZmNPWOVQQCC1nSzoXuXbtBQlYzfe7XgmwJg90p9i8L9rzZBOLd9VVkJwRf1P)a8cUmNwWYkvtdLz3wTq94tjAVzLe1MQXMrl)vtZkpjFE1I6r6kQffy(LxmTO5n1uBiEDQNpPA8Is(Wrr4W(15SE83gSRKCYL9mLZUI2C4surz17Q)XIMMQPT)n7t1UWtz0a(jGoeV08tjYdIsX1dt3LlMGjB(p4Z9FyXKZPb5bscg7jUtVPyM8BqBoWRTyAJ(JQOZ4VgO0EB9TZUITBqqQDvvDXFHnlLNc64Pxs7ZicWrvtpy8L5N2Cl25r7OViBrzdTPf18FxvrBLDg6qdKVKF75fthl(O0RojBuDf4tilAyqiTjHOBOpcFJXa9hLAXzzxMVBDD1nZ1nsD20lZpC64Irznv0M5YkAZXF4(sNHY)e8ViEkwpvRjjSZ711zxwnTUymBCjgXOIdNUF1KZbPOvHhoDEt20r0i2Q4JZQX(BRYojRG2aBv0VNFvXimDzu6ryfbB1nk7JtPsNNxrCVSlFrZhVON(1P0W36b)urZvNLvFzUU)tT3rzZ)3l0FDQ1BOPpRL1RlMxCErjXTsnzX6x0EbfPo2x)mJuNO6EAqQ3MoxUg0hvoXgzlvUXUIFSu5(pOu5edUvXq)bHF(wI8TSYnoHEtyLh8SJiNykULt(w5vKIHUje5H3lICIRkNZ9gjAote77TK5pz5KVAXY3kWIT6c)yfyj6ErMdDwnjZjc5FSAGk12CdvbLub(7vfuAO2wfuQO7I(Npwe6CTWTv)0SmT2NMLku(0SiUUNMLOu9uxOsZtDrBKIN6hNtGR)TPAN8s3aToPvYnHlE8wY7nZclBjV5BHEErENSL8El5TG1)plCVnn9V4qcMXt3lRwyd9Ly(BMu0sJD3VWW7vw8x)vwT6uUnsyGvEk)JWXUpGhNkTdMubF6uZEoBD5wVD(TZBYNWD3X3gSx2LZ7BvOLQ1psgcFTM82qGK7HfVxHufhvmQU6O8Pl6qh(RYmWX5WRB3TH)dIOO)iowEfR8NUuoqRCL)5)qhoIv7R1Vn4IQrl4o2C6isTE449pE2zF8O3FWBoBaCG5OVCzD1IPJL(wt7zn4HTK)f9mv1JZv(EZ5L4FDvLZTxcjnk(QftV00hDXINC0vztNMxAul1cI6ATECrwrzUQZGhI)XUOAkP19G3ux8xV4)Ar246SMSxCggcxjIBap6ee4zZ(oYq68FQfedCCqcVRJ3Bs28VC6vzZGloNwnnNAw6)D40M866fZAkoVmxp)qJQH8)Go2CEmjqtaGn6ES5klDYOpK5VpDww9xSliVSKhpfAYVZkMy0mZepXBOjbX8n(EYI7o6AY)AZIAmAyJHlYgL)N)j3tH0IaZL0)5F(Bh(kABsZc2reVCqd(K2Fbrr1tGdshuNpjRykmjN4Hn(UNC4BFhwmUreWgo0K6xPzLKGHrrjoro(oEX(VCWTd2jY3ByIVxuGBKJByerVoRm7wmA)vGin47KiLEVNFePK0lpYeP0x47NinKtKg7MqeK(rXPUPPEulsePbEbdDJIDs8JdC88jI0gHF23sKYcJQE5KULiTxoPpeePPbUeN0OKyhx3y3uoNuV0HoooUEEoXo(USJ(zHvfrJUOP6D0HHhmUOzVkIiNF0sNJ7PNebWd8BnlEF4r9dXl2bXiN8W8V1BTMIfWAhyCz0AeFE0o4)JwAi2(WTYmDsJXHgN9XJHiiYA(DrGQO6SYk(h0q1jL2pgfe4Le76qdF1B9pPVBQdMB88s9csCu(GxCsPYe3Q4AcXvfxIe2H6IicCu1SBFFXuegyH44lEq)9MIs6au5JWk6SSZf)wenuubcPd4tudDP(aBga)f2uGBi0sMVySNsMl5iTtfQMJT6e37QJ4LmoXM2(jkSZKSOCr8u6N6oeXpjIEsVaA6Gle2ULnho96IgLKi8I3VmB(C5mfNoIxXBYSINkEHVDrr54DlP1sDSLXR5Df0Sxnr3A2gK2zGDI8fmR60RkUOzFAvX(noLeJTzF(6Nkca5FHtBkg9LBP6uXkOz50YKDl9BN8(wnWNUQGoWQMVcB2x(uX0Xv3qdyDCvDb9dvOTrK6437XJMpvqAHYETkoqDjQkuceUdH3h(jJ86TvLJpLKXJrOX)S8koUU6ISPSGkvyzaE5eP8eDrKuHI4X1ZXXJ2sbHL)4IgsGBicOOGJZqO0oa0lZ)Z)ep5WZo7nIkf7vikOlGWHYyX1ZNX1jYlmnokK2jXQ94QcMW4wAsWQ5K8YmefTl)jeuGbr481OW0WGWK0erdtB0XCcAjABnyhPiMEdresDFXSGU8tHUlYjTwfFivXGt29Wx)5pT7jF4Wp8wAW26rE)PhrpZh4I83QoQPRriao4CPrOGYg06xTA6HMrGkh)EvXOCdYluMGuA(HtFBROzLOXW(abVgxId(lhqJoqt3C2TmDqoD3)j1FqHezr(OM8XSwh28NVFrmDWPveLznvywgBE49V5TF(KdOjIxFk10MvBnhywrFtaI6)eX8xWeebFlnIu7ULMWs3XTzo6jzoI)cJ5OhyoY0EQdNrtDQmIrm((mMLn06mr6gMpDmxLgZYzCK6wm2foVjBYm1d3KD(P5nqdjQO)4BWYB7Z44lgaIqK8HRcs9ri9kRxypjjNJKtrygArn)8kM1CyedSZyOthyZI4rUHZ)IPGNIif0xMvipei0bspqAMf6ghsBbnFgANORlREpx)ip6zSRN2E6fZ5nWfjHoer8(eLkMAzbSTVX3MZc9OkWcDW8Csn4m6KgOYOK1QoSF1L9AIJcX9ZTDCOJ43NBxJYIlNcQsQv3)GpC2bNqTPve8pWFNaKHcstntdL(4Dl(sco5AU2m5yWlyhQSCht)XRZRRPD7I9cY413kKNN1h7Y5zxNp(q0cCdg8hU(E(rPVeSdPjt8RGq6)rs1GiCg7dEx28wb7l3WT7wtNY1keK3lRPPmNBzNh7aE(dv90TOJF2GyyMBM73X41pN)JFN9dy7aCcfsYd3OKue64ezarPYK4nX31jmiwLAgI8Mytjic2X3KGGfN9lM2Cw(xBePyI7q6OqUeGVxK8bdOvf6TAzVQ8)9IIzZYhFAzflnsOU0dcXv)en)usf0GKE5aX8OKXnraKgf1rLh)qAD5VKPDaiaYNphhjISfzjmd42VuTLKOKuSciENY44YAXN2X3LIGitEexA7JFqiyeerk49sIRGlP1NRFOpXQwYKWlojGugIyC474)RjxIK0qBjubxIKi2PHlAyP4WgEkHB0oPMCfy0gT5k8qD2bXz(MtZj2)JZGgrdK2pT3T9iLygSdr437Hg(XGaWn29LrmYdg5arYqhHK6NWiGiAeCSse(L4Cf8kSFfYmI9pLmweNO0)XlPUmlkehK4eeLqI)qldXPPdtOsIJt9iLJHbvuPIgXC5IVSpjxvD2PZkuM03QWtNLJu8HKBIOtOAG(I7oTyIiDN4IQkk3uad(td71a94SZTnQI)Z88zCLAfIalk7Oc02ZmlgIx1k)NGPGoHe3QqjSSUeMOXswUOyOf6)XIPkhuGC9mJ0)O(4msD72saz6UL94cKzeFFshX86CHWAg1j66C54vV1K8XfzArW)2GllRopReQSs7rek3QlZsfxEXqIkZ8vBo1)Nbv7y1cE8C3IitN1x8US6XVyV8RZlPNIe4)TgFrvSTXlSvBlgnQ3r1441qsfkxD(M8VECfnb55rmS89DtJI9PnT6h0CCZTUfjTpu(JlX)46SB0zXknekZVa5HNL8ikbIK(H6B4SoLkdeHj9DDOtn8jjOCtOt0yQq0PuMcfTkfQxW9UdtyCMSrA7m9Tb9Z6kVSxBba57cc8h64fMeNK6eXn7Emn54ehLgf6775a7goMysYZJwZe4DWBP9jqldMMoy6r(1vQauR)YQYGqfUdDPwMyv6L4cnqPV6RCDjvzcCCJJJ9IIXrhc6Z9lPHzE9qvgiY(Ed3Vo7cOMit297Cx4vjPdjrAdJdDtdbNAEFWjLK2nXlMQWned9o9bEoj(6IlUOy0Is(bBB64ojyiPqHpPIHBGC2oXDyIh9t)qh)a3KUFY)7QP5GSwUnT9IS8ulJ5AUnHKvqt4VYlEysiPNyqenIt5(a0JgSKi8bHH(EEEqmoSyEu20SlZR3VSA0x6(jx3kBu4q)KGqAarK3XMRSU(jrbjPjryik35)z50BLWugB8u5ROPsFh6mJaytmtAiyovx6qL0upC2bypYe(a5q)(vtivEB4AQkSgVWzXcojWrYqEaf7WryIq)ltIovP5FDw2uK77YjmEtxisGvtIfXNzswHoZQzYEBMuS)Lyjx2hL)URPzGu4k7Dk45jDgouzgYuSVyYvBKgjjLYan)7fz15cFVRy4Yn7IyNLOT1r7bxGoUfM)MTm5c5ZS1LVZXwAfP5Fr(cLkN7LPERCQSD8yxm1kwSlMAgjFtvAdZF9QEsY3ktLJfZngXy9kIRLZ1r0LLUi2JBPHMxXa34S4Eg5QPIojcTASREeReGwp6f1V2HV0QEM528QMaK29zfd)LyVMR(XSS)apWfu)JLcr9eMG)7AKZj)xXk(4f1z8Cv)xUD7511v14a4NBJCbRV7mBobXonIRZ4arWZTrUCpWDEOlXFbsaHfIq2CvC473K0gS4EUYG3qTP7fl(NRJFMmHVlRKzpZ71mWZnzB(3lYN3OqaP75G)56YpPJhpIm)1t22MSsOkY7YZaIyD)O9)Bz5VNt92qPBfN71SOPQUidH1Y9C8)CBV)1Cit60CE4R9lfFpTk3)snWHfsKa7gPpFtt2ORG1rmGHTZZQ)mhgQoFEv5IM8)XGDs8tGdF02Txw3)CWoHrSiAWnKBvrzUbiJ5GM68MrxPszGpEXfZbYzXI)FQczatOStcvMiwjKs1XEdeoIdDD8dDH1FYFfm2FfRgQl4hXISU0i3KqFhst0zz10GIfcoCSLddk4izB7L2JP0o7JhBfw9DggmZXQgf00P(dWr8f9SgngnMN8OEjnhsDsMTQE8MNELpZ7C(jUj(HWBu6jQx5ouSm5OMf7DUcUQxoxzmLyyZrQurwDWMrw)8esvfSmyK4b6PQoHdUXexRWc)HBItC0HK(6voddIC8IICv2PwrH9kVWHiU5ssdDGbKTiXa4gYIFo5yBDZD22RL5GrjOB6XI)h30e)OaViH1)x)Kl3k1cvyS24MominneXVCcSpRX8AAa9PC9DcI8GDIF4MxBVX1bPEsCKFKOpO33MGEGxskvf9VlzFlcUY15NJ7m1ipNnz0J5GSS1w3044H(((EkVfyoVfIQsDCccPTYpEtBUCMUHo03IzXB98wk6bjPEjEEe96gpV9GWVZGAhmYT44f56n0pnoXlgoeiWICZp2FyAStCAquCmsljEoK9WFoH)qhFp3iIOYZn2hWpI8CcI9xAACkX)n0lI5qgdMFT4pTz7HLzF162HcNQL1K97siZfrnEzU6Kx4hx4PZ9f4B0VxKFtE9Np73o8t1zZMXZtR(JojvMWXIElA(3m6arCz4ap9WTTVqpV7C7UKGcIA3dKbc09SNNgWYMaRmTG2ErFHFJhpjpmTVoUjr6g5Kmmo0XjIjwbYjotzf2OjCHCrwnRll)qiw4oX(bj2nltUQ1Vo2rClSoAlMLvVLHNIRVz7ixaCkOTujDLNz9nljMZAAigkHTPnuShsvrFA(l1nofeVQWoD9nHBqCc4nYZGmAxgcJvxxKynY93QKZDdATnktk7kyZ6B5nl93KTSon4wFlVj5SKoLLwF7XxDztGsu9(ZNxnNPWW6FBxhpwE(56LMK4Xd4NOGyuKSmRwgER1Yf7wP7GYtN0HHe7oFxIFEqqSdZ9Z8fB7oADwX4pxIKiCDDxsgfMkePXrUHjUuJb(P0HedPJy9Od79tPtsyHR0qV04Was(AsEMuREp7ZnFIWoIRC2zOdjwg9pHE(Ur0HH0xJptNqCLscJ98tIPJPqijON3jH8(Y6giuVK1ZdW(ap6WysMwrMRjYRerSJZIZJ7WwlFFEOPtnyicIf0xjMsgQfAh)nRE47XNTng(BwOPuD()todZ4nSz5gqgMqcFOLNJZWIK)L4(hgKsRab4OgjWLdPcVdtmbUHmo(PUHHY8TonfXPFSBCOxkrU0QXhHK764k6i(nB1mk2dDvQ9arhFUN4Q5JyPtVAA29VtRSPrSbGmaVfblclxCrynIy2P1a4Q8SYMReQBS(P)i3y0)J99c8CLH9xcjoOkB4A)bMHjNnU97JNxqcc8el9IwFhnXVL6s0eDl1KqJQ0DargGq5H134UPKsKQJM4SRcdzChjrDqM5JzbDJpbaPc8m1MrK4ghGyKXIvlNW0jiokXpMjItF69S(UEh1HW8ILAqwnnFwFJNye9shIDxuCapyLCDaNCTUgB0P2odj1Z1dyAJcXkmcCSJ9DOJIcLmXrknKesRhy3zeyI3rRM7k37oQ(qdIwQ8y)zu4VW6N(PZzOdD8tsc8inN4uobbPdJjn3D8JdPLhR2(UiVGRBkjzPyVFe)KIa6WdIxtirysBTc6PT3SVqVRhU(P(dJtinAPTOcrcqujgghsFqIHmtM5Vo7Z15Z(S8UGydMJs4jUIimIfcdqT0L1aVg)w7CibrkLiBafbde)6HaWNW0SzNv9w27j9qmkBglMT6TLuXQOmeRAQkZR53MbUHWQRMxGgFBWORfoBcXE8X4E14D6RccLkDQkLzPTmrziHckZMmJNcqQWx(SQtzxQlQyls9n5XsR(Tvv8E0c19uXrzFvdGyQhxw6RlKxvd4AJXSADn42JXSM()iSs1VecIk9lviVypy3VgDkF5VM6oRHK4081w5xRIh6dKau6xHvMocZHvyuv(XrJkxmoNF7BCeUGo2XbzWK(bUoVUmBgcf(HMDeK)Au5)o9TgA(1KPDApt8YQ6zse3Ij7cpxZjJvFDuUikW)4uEAAws7TfgNZ6XoyA(e2nltpnbQ723UiRECrgsY6L9iiYozzH9kEaDkI25ZF7X5Wjel7LpRQjFs)1lhAF4491HcVv7ZFIEQKV)zV8RkMoMiTnPQPDS5yKZmW1I6mM(okHczX39E3sVWS8sE6dBM466CJUMwdkQHeRm07qAaoe7JhNxpjBQrKPQrhjxIAzs2xHfH45Gc3cw8m1wBnRyeOJLIErjYfFz3afFAdjKMzHYRyivsKJBbQEHpjDAsOJHuzz8iJsx(btRZG6v6soTjB0x0jdScv9Sv44rEke7u1tHGTIAo8v6FHmQLy4JPlI(1A6tXv9K8Y8RZ0bqSX0ihlnU)ZHRygRtMgWVsNyuJky)Qh4d7YwjKYQXtSEFylqgJVvP9vH0Dd9XyO3fd)UAFndOUfY4j4lprkuG)LcpY011QJWqOs7RPjwIclC24ReiA9QqKmCVlnzwvnj6AZ(aya0x7rVey1c626hWajtgSZFG6b4QXEgj(LD6vf5LJ7bUUA9eAuGqvrFyX2YHgn6BJVVOpYtpzbgQX7dQnNaf00JlQ)kaBU5OI23GtOmHxPq6sOWuk7gGLiBsmrRttyaHA9JJCQxvJOkKiOQs5lGeFpZoaVqowvOFsfYB8XF7S3F4hoaBm7bR2uj0GgT26pTKyiCv3XkR4wJtfiU1)ySfgVrJpwjQXgOonkHpW4f0ZGIvrpuvSY5N5pQyclCw4SKf5peYVBdNVFREVbXx2sFEXnTgjZftxkhp)Ka3eGOpAgoSTK0(5Wqpaxx(orPXraEcFq57GTGcpR0CfURdrQIAcoe4sjRFinucqHGxFXuCvqDgRfSHuNjYRcmzyiaXzvfkf2YQq1TJiosXucqEkiYNYCIdcjfzKayMwGoUEtQBDr6qkEjYpfqhnJsoCkUIhNdLiuvi7a4(FRhI43cBlbWcKnCzTBBYvDnKqpmvTTEC6KqrHYupJLMsCAezGrRq2sPinSZZx3Ify50d)FbotAaKoCMI0wLlQeaH4XhCc27sJmJdYjIsL4qy9qTF5S3D4hOhTUf04O29p)QSX4UHul1cnv8o2iuRZhocHj3hZEDfxG7dpsoU2hcAvP1UA73ZKVLDnDpxYUEXre0cojkIrgHY79ZUE2reVAd2scz8zX2zRElRmt2QgfW58WkOhgmSY1W7fS1DRplV7ORq9za6MPEC10ajxRU0oGNLUk(3ma2dcI13HcK7IaEwK)qqc(I9QOZm5a6Ky8cze7teCpIcDTeDsPe5uCgaQZP51eJjoksPSZax5)uWzGTpTZWve1npAdwmKKJvZGoyt2Fj6BD3Drk7msPQdmhYfkfsFm0V6UQkLqhaU(CRstkXQ39qhG)U0xQn27k1UuXcTT2L3d9Iu7i3CvJ2evGK7reqT8thDG4khzdkGTqMziTuYkqM51RBeeK5jMUrmaLED6gXFINU6gjziVv5ijmDRLQubR3cfs(1wFOaHW9HProb26dPUzKv43(3PIqcQrU5A0wGXqYgMOHDueAPy7UsriydKEuesg41snHKAIaLcU363qI4zRFJwng23zf634cqNQFkXE0Srmkmu6HRAdG7tZcHQnjaA(eGQbtQYLOzJszbtrTU5kavRDvdTJMnIE0YHqFT4LRrnhtB(UjcH98wjhAF1MPKdxBJFQ0XXBP64W1H47IqKppTj0HWmF9QMdIH21PATTwogEdOhLCwIMn3ptjC32WPnIGY9kC1Fx7aDZ1XHJ)rMmu12BQ4YRkr4p3XFYe)iHrImFefGc5cZmL6h7fgaa7Xj03)Ld8za6AStysIxqsAucwjdqH2MWdT9vfJ(Y0Ce)EmSlhajB10SYtYNZqExB)C1poF2)LAYsSz)iablJeH5TynsuMYeKKAMaWbyySRwPBAXqwQH1buC3u(qqUW3d0qVAijb4bxVENtbA5ik1TDvNmhhvERFxafQMWGkp9QubeEgqxgyoHjzFDxUJeDre7xnNbP)KwxDIFmzDebzR4idw06AAflxaGPIEdnoooRPjVgDey471C9OCx8VNbaOQ3uFiqwNZ1i(n3PdF3xHMAWmv)jSWYud2jTUwmBP3i)YLjHMcQQB2dG8NaU4XScvK5Y9uyArGazciRBWoaaDGZlTjczfzqbAN9oxBsSa7mxqt(sIcotXLHZgKyi1zZ29cAHJKkH)lZo4R)4NGrm5iVjd)VSIBW7WLleCpKR6)CxUFHABTDLsS3)TF2sMIyV)AJl8hpQll)d8SqpxeleVlgoNjTP)F8ha2GHe40)9F9sMB5m)f8(iAuEDP0Fh)HPAkCKWWiU(5S)UV(VZ(BupWylBNaY0ylBRaZCz(hEzalSCJLHDcn3zzvSarKSkZczGW(Y7bsbtVn38JADKbAbZ2OarZ7rDqQuS7PxpxjQtBtv0gVrAG)rlQrsBYreq91FG6JtLECRfCr3IQrE8LOhTA8TX8gtYoOeEqoVBjHgYMCqijlYyMni5Ea)Jtre7Whm)cFazN4t2y3MNJvCkVjhqg8s2)U9CYFApNSv4LWLdhsABHDQSiWuizHqGPoUc)8ZjbUkYAY)WIjNBCtHG0bTwEb0qhMKWnVl7eRy6ScE9WD8wmq5fJI6Y6uxNT4hMLl8fQMvPUstNT1UuUMn6s7X7E3bHjyNzY)Z3TKeMMd)(ljXMDpf2NeeAPW7KJcgmzITZvb(r67YwlTCOx3lIWNvNYZ3lCVpy3L3gTpy)ZKcqiUeOQmPv1)we4lu99PUxVMcSLKc8bavi3t(VToBCbZRJcbfwHG4QRqrOtSrYN8uyFHWco3z9BFi2w0j1Am2weGu5PFx8TgTgxIWTMkyAH2NC9lBF3DVw1gn91El9gndJ17nfFC)u8cQDo4xB4kLLkF73PuSHWSH1ly3IAa7PRkhxDdZsk9jgUz9crXrG0Xbow2BAfIVm9OpjhysUmmFrU(uTO8n1zxQXogPrHmSA(cHQz4IwbEaK5dqg8(V8(MOsXTelrFXEEZqN5(FCrz25IBHowSBIRvwOBm7mCQhYQEz9qvL6Pod9cPjsJ9hVYdUFqymgCJl1bZ)F0SOY7XyWm8Mw7ELLyILMBr4Om4cguTVcadDEt2LxYZNr7i0JMBjnUXumtXB4SLRV18(k2hZ90)bvYmjQ(s)1(nNurQerIIz(YjgVS1HoZebCc74GxF70SjfJmuoeM(eP8fdTJ528uKtZ9gCbAYx74O2KSMH47ge6llgNzbKOi(Cnd0x5gKLfOV6VfJByRB4yJ7UyyOizQAZsFHETxR2gHSqaCtst723A0syG3mq0DWcI()K29QSMTxJlazpxO1sJcHaHC93ozwr4QBI2zEBsiYBzW6wRKcZ3YjL76SvLS(sAAUP89rMRz7nX2ZzwxM0QGBusTsVUgDUgBK4ictbQSujYuusEQ9iIw2DNPDOXz6NOLmeysVlTgw74X3(Qmuhq12reh99FF(0lretYCCLPytAsI1V1zjBuqmNIGauEpx1jV7uUWr52kUeKgbNL0xnI7CCQfTb08rcRyleuyvhTGejSAH(E)qc27ga5npN4q6ajUuQuU7r9qY8MKhktSKmcPOJ(6ctF1XZuVyn0XBsixdtzk(JE)wBqkVV4nGD4OPIT4R1P)wuwAAZ6ASt4SQ3ZVNmK7MdeNQ2vR3EopLvKPkcgfWxHzf0nOzzfZfEzGq7SL4qtbZfXPKgIjABUtXHFvS817wH4C2ANVetyUjA50sUqIyqF)6DNCXM00G72rgmznMZ7Wo3GqORbfjPTKfAo9BxgFfqvwpzOqpoTtfqG9q(W8(XG3DW7p(n)27ry3IJvudfnWETuV11Rd60EBJNlDg38pSBjgRF3FS9(iKzxc(qD9f1hu(IIK3(KfmzUED(fziRsnCqfsdM7QdQMFtE(mDgiy4YjAxzVUCccqOtZmoirMp(SkCRSw1Wpq8Xi5ZwrSpXKSIjQ(kZFmwmo1JSvYKez5jrfucG)hS3WmPc6tARtLzwKPi2gIG1BKl1XbEwZH)aCrNKBmTJqENzQL1UT)2mNcmorL4WwDZst6X(9weNQfQhG6v2fslI(CbJ255cfkVZ6t3JMZkp7OYnFMC(TK2qhhiMsraKHtyAqv2YkJofMuPLS7CmJdo6A6V9xuJe3XidAlMZZLhZKo5YIrMfCCvXCKPWMqsaaJi1me7MBz(GwUTsY4xZTCz575st72153PN1hUS7jh13HlwGl1p6ZxqA)T5Xh)Ys)6EJ)b0YTc2HNAhWSmDj7xzv2TKh7Wt(gJZZWTXo3x0U9KyI8mr8Rn5thVh)eli0ISOZQiX4XV7jKLCukSY)E0JjzB6r7dNLnMF97BAyN2GotB9w7HnHOizyOIqsDJHQgOG5X15Jlu3vhRYBuqODE9CyNq5q5SYsyM85gPzn7eWayRMU5O9KB780shEHNUQ5kCfT3Q9IeAzINqE7tlJwdJzfUW6AVXrCypI)5m5n(r1NGxABN1TIJt3e9KuzskNSyt0qsALGLer26m(yz2cYkfoLwi(f7lV)hFXPFHuVA(lGwGDJtzLVjv3LK9yd22wLsW)xMQJ9IAfRowr7ZMYgggGOK7ywdApKmIOKNIU04V8A5tE0HV(1V)amUlz3))gqSJHnTuMBUJAdD)sMNWZ4(Y2HZGflwihVKmlu2qDvvVFdSBhy3T1MrbbiTNrGVP3T5iyufCXyk401RQjs71BL5PAVC1DgS)4oveuPcBwIieRJc(RnNl58RpRItqXmxbNM6EgRYBavM1mRWspk6mXVvtFTIY3EOYa2puNvyhrUQSJGDb6tQpGy)FzRjvlAMBEP2zicP4EdLtX5VCRLzJKhy947nJ6xFIKWSxxpjsIoFTwcBlGGbQl1vLFTKwauTl67I)0DFtMlU556gezkkbfhILTS1dTGTDhvYK0n2JfUMTpsXLG3myVlNVdZaNvL5Ct5Vr80wfv9RGAc6wMFN2yR7t3bc3aO6RO3xFWB293EpYY(olelXSmlBwL0sb3wR910CFn2o(Hjv4WlyR7JhaFU5lMmPAQn))rJYN1ODFIo9N6ogTpzyTKdZiHgP(HLxMeMDGp9Ym29YJrFdxaj1AJlrbdugurFpSG)tnJrBEVBVOotQZHnMza0W60LPDHSsHjSo4RZk4X1pn45AyA3y2i)q)htXN9otp1fkoDr5UnNHEDfy9YYQB0yRd(La5maCEixzKM2fuztQiHy5xcucXlvOr8Amm7QmZ66S45)7XVF3)5bNC)n8jNvK2UNld2We519Xm8NeiDKPm2DnJX6ZvaZOSWg6VeYxzAaZNr2wuMQhsWPIu08r04IMZIARlA6AcaWpAhj17bWBGFFHzoAUQN0mWeCTv(zmELaTnhLH3q7R5RawIoUPZiJfv2wtBKShrtRbv61mPBUA92vB52ptKat95QLLZd4b0WuT3)tIf1pSbkS70d)g7X5xKpDEX1RqIgltUqI8WnFdZCkSlfFsHyCn4dFHzKb0upEzMTTvYXUUmFsgItw2LvSY1xz2g0MKB50Bk0O9OqEaiih)WnLjwq8KGtTe(DbzAYAgr4ak1tJqfsF(fwjNwElNJTfgLyAzPnWK0sShX41ElmNVHfPpErP0e1MEN2qo3(fv9PSf6isSVdtYXbL)xfGirrbi1BT92wBVXUYJK5fWp72EdwLYoYB3iRXPyxJByPMBXvV3wd0Pcd9TgOBhjwZ8uXaDS4wc(1ERf6q44yJ9j9hxRgaUWASw7ZAl0Ln9Y89VkFe7M3PTBlZgNRqhEiMgUb6pbVHsuosdJfZgN1qCrBYRVg5HgstmewYNYS4WBO2qDOAnExEjFBWi8vB9ATLdU3p4S86d43UC2n(kn2yFEKTNWWQ3OUSL3uGZNxYDLqE5fgbU3h(4jhTlc6lPZbpkNeJLnbQrTyQXyZMNNZYTEDkXYZXFwQcRJfdE(kqJu1C6wlHEWhoJzHP1EQCxJJcJLzfkqR16OWWMBK1rBrWToJLYbnMVlnSeCQSuXI2TQ1Wc2kJ0W6SSP4YqFnb2ZQvz6PMnDNPVKo3goX6Oh2mJI2goXiuVvX)W2Wj24Q5q6ayf498KlCIbAc9upAVEEgoXS4KDB0e3oMRB5xKTrtSww1TrtSeTAwdk2SnAI538tpyhV84fnX4YO6P(5l)8enXUTVyG)o8CHiyIBFx837fs592Hgck4Trt8sW)YTrtCfy0n4n1f)1l(VwKnUoRj7fNHqmBdsZ4Trt82OjEB0exohxZp6esBB0etZh9fmRlfdo(fXxf3VOjEj5hbleC3gnXcBOVnAI35Ba8rK3xelhAlMPUHZ55F2JowwiYnWEU6myqzrAqOtAIRJNtQxmYYTof45h6Lg467h4feZrjHVp8UaxZfwOmLgfu(7bWlELigO6Gluwy9LinSXf3VmdSvxbA4I0OF469UJ1flnd3(BgamGPu)HHagIqQRO0camE0ch84wWGry6Fh4GHmYdVtaHHvweOHaPhuSWyzWV(Z44vFzan2wWWaIt)9bgg2adXpVGHHlUB5L3ZYBiAy8djI9)5amm(HEqJu3h1jnpGjDWZa7xJl4)hm7xdFTUYRdKVl0w6XY81dDaenW(pm8(Jbx33zCXW4MdHd3HTalojNuF6muf(ya5nTVfAYg9fGGEt1b2fashEMrAFvLZGn1VoyNy30HEP(jjbEXX(bSWWpiiDyCKxKJFCyACSave2chgRboma6o5Y(pmKUDtsS8HbCTHcD9DIyV26kOh4fC5QKTASZGbK(lfFkviYs)4NbWj6hrmZOnyrUjxWARjazPDl)TaAgRlMpFcGHgqv6LM6aDGvKFIbrJ(V3p1gwOhKMDdO6E(cIgiR76hYznardgBKNMOObjkrxu04fM8UyJUF0WPH5LrQgH((7dnn4xHA9FTuQWsdgKmSAS0yDS6AdTgRaSGEWmgEFOhIgc)2ISgYlitBGkcIzSUGf)PwuydaLPN8hPKFPk8T1H8VpjbyILLG542IvLUY)iaycOGNcnaTny3DbhY7sL124)s5ojw3pcq4)6avwmY2yC9NLX5az)JCIg6r)tQJJFkT0q6qfd1QIddI8tIiDSURaLkwFLMgI(7pHakvePAcFyuqtvBamP(8bohw2DZS0Zo3F4CO92Ohn4CGiA(HaNdgWCGn8PAI1kDXZbgWCDhXZHUdjB8CWmzJSaGNhf4CWy8zJNdmfPyN3OW3kZBRd292rpxzhTGgtbQkPTHU)D)Y6iwEvzCVmDZprbF4)F7DU0uBJeff()swpOsTLKLm7OGqcvbdUsc7yQucJaungZeBCawW)9PV3(H6wQL1d32wMiwWcfhSrO(15EUFhwSHuOg5vhFgAH9HzsKMtnfP8j8)SXWVk(wZVHMDWeS9tVlEsY1xZcIJ0z3JHMZ1xF1zh8D0wi1epP5qpAzzUrjXwvMp4OZYBqSKY2TSYYt8UBe0muKT6Ad)yBhplawOFGx(iDvKdPR3JH)XxkWojHaj4)SejX(8x)IXjZpg)HGrMl(IGR9nG5k0PmkLftpMaPnj7TdscawqqZUQ8hqa4cdKlLF5BNDIAmbazf9m6FJ0bAAfq6066laNKSoYlOKJm0B0LLQl7uIDImI1Y5Bd9HKwnmRcvbAoandvgpHeofolTwW70qayUIJSJ7wHHfoOpHX2DVSMR3uZ0l()y9wKNfip2web1TkR8RoOwb4R)tsI1QgYL3D30u6Fae8yYoTrVy3aTOp6PZabrEeVYUfBT(g2t2Q7sYupzt3zuwpzZ3Mut6j7s33txtoayiWpEyEc9HGP0NaWyc8X4PygfxtwtUUDqfORUn86uNJVLwx(bLKr0eElbec2UWwaMlunCE2gsxq)021LUOqlq9k22(V9PdJCJCIcch4ffoCuG3wq4ITJNwuasRT0TO7p9GfDHsTrFPGeGAUoaxjUsgqwXSaTVj8nmlWFQkVGLXPx5f8qJyAYMbLJC4qv65M6X2sTCsDuqVRzKrld)wX2w5fy6c60o7zkVyU2WBsLxGteyw5fUMi6cVayewiYIq4fvXySJWl0XCsHxU8QX)84lp)Ql(7VRfuJTrbMxEi9ziFr0dq71XHh0F3BQemrDujyStedNJDjAEWObsDADnyu10CJRbtw0hbT2x3rdgEQlyxFCuIemG6tFiKGzndhLvAlM1pRuqHt7vjsew4njBWrmko7FXqlvHFwBghnugQRWfF(N)cs(kC6X5l)VNtVzAsXG8UnXKBJC0aDGm6Nb)ihpVbEJc9h6s3qYBF6WHEeNH0VIcDjKqyKDJcMI9TGF1yYmHu5V2PKPJlymYSVncYpNM3zavvxyFOZHejMjSQtB7iasiCYWskrQEMPvS81zBGQgLkLz78vfY0qXUnh)zSpFLByZkkaAMpYRr43jc8mdw0SvrSy8BpTeJ(UBtNNWdwurDhZA5sOXVJFfKKNoTeDZL7(Imw0E4LKeGkvzKO6LM6emGVKmVIMxVUp116m3ZOBH3OvQtVR)KPFTs21TDjJ9gfE1kUeiZaUk5dkS62fXPZoAXIu9eZcUkmGqneva8tZhKWgu31Q)eJpZ4AgBh0mSI0OezZqKl(vijyqqaKcXfUWa2RGegfr8gTgSzGUNHofAg4MWHtMb1a)k51SSzJBRrrE1vapd0rR1bpdbSxMK(XaC)mVy2ogfd0px2O6KIFgkmNNf67Q0qFltIHohbHXYp3UsycBQdkk6PpPckKnqlYUVqq48HgypegWopUNHWSaRVlCWuvBrNUijgY7nLRDr89Pt0UY4NsxaruSg8w(yaIHD5YmScGxgWFyltXpmdyuu1i7ugI8P3MOaR(81bVTR0S5GjSvHXaC2VnWsn90yqRCXcAmqiJg64sI8iUb(dzkV57h5es8c8i(J8jq1ewBEcZEV)yJt4wqJHCsT95zX3mf4o)koyvpHfY6zaYUIWcDXupShPcRCOX6uWD4XS60ZdDLypuNKW9ivy2KhaJxz38p8Jksfkm3wEgkOQT(bGpPZep2Amuqq3mTrD9quaf49RI2CdRHm3tHztVTVbrbMQ1DpTRLOQY1zyRrgmD4X(KS0cTaQsxABInyOCx)bjlDbUn(5ZhF6vqAPw2eV1uMaRbTrq93cq8BhBN(EfPxP7f6Z0UE9OHD4Y9Azxqp6SoR5eHC0zxIRgD2feIrZVcBhLWEl5ReT4xlJNNud0VW6OIIDAr5iHPpt7QLk0wB5LnNm09zAx797NBocat3HNeOi0XHs)(bIZZ87NRZOa08g(HdJ8cf7AqbiWkLFsqey(LEj9wabgKigsGjEJ8CcJgoiWpkAaDXmueApNGWGapIRBqupxz(Asn6UjojGrU(IFdo5Yn3l1vwfCVL1nARVi0v72sZguP0aePklywNqJkNnnz3jmqx1(qTJEhGvMsr9iBo8rkajMFC5yz1npAA69ZOVjQL78ONVi(1Zt(DYuHJ7kR)ZGdICmaeP07sNe)CQsjSnatgzGgTcrtGHkfoGVXo9sENHEAn2ZCvqFh737xf4MCjgJTBkfn437kP7lD6J6qY82x7SwBxx6J1MTv3oHPVepfe)mz585q2dtx2wm(QY(8XW4L1Iqq5fk(aOKusOskX6lsIVv3oyvQbDFO2j7LC6jFrFZwCrW(qTREHA370NhxMI8V7ybkwfwlfAuR3F))p]]
    },
    
    ["Minimal"] = {
        name = "Minimal",
        description = "Reduced UI footprint for immersive gameplay",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        iconCoords = nil,
        category = "style",
        order = 11,
        -- PASTE MINIMAL EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
    
    ["Disabled"] = {
        name = "Disabled",
        description = "All TweaksUI modules disabled",
        icon = "Interface\\Icons\\Ability_Creature_Cursed_01",
        iconCoords = nil,
        category = "style",
        order = 12,
        -- PASTE DISABLED EXPORT STRING BELOW (between the [[ and ]])
        exportString = [[]]
    },
}

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================

-- Cache of decoded profiles (decoded export strings)
local decodedProfiles = {}
local initialized = false

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

-- Decode an export string into profile data
local function DecodeExportString(exportString)
    if not exportString or exportString == "" then
        return nil
    end
    
    -- Use ProfileImportExport to validate and decode
    local PIE = TweaksUI.ProfileImportExport
    if not PIE then
        TweaksUI:PrintDebug("DefaultProfiles: PIE not available yet")
        return nil
    end
    
    local valid, info = PIE:Validate(exportString)
    if not valid then
        TweaksUI:PrintDebug("DefaultProfiles: Invalid export string - " .. tostring(info))
        return nil
    end
    
    -- info._parsed contains the decoded data
    local parsed = info._parsed
    if not parsed then
        return nil
    end
    
    -- Decode deltas if needed
    local fullModules = {}
    if parsed._meta.deltaEncoded and parsed.modules then
        for moduleId, moduleData in pairs(parsed.modules) do
            -- Get defaults from the module
            local moduleObj = TweaksUI.ModuleManager and TweaksUI.ModuleManager:GetModule(moduleId)
            local defaults = {}
            if moduleObj and moduleObj.GetDefaults then
                defaults = moduleObj:GetDefaults() or {}
            end
            
            -- If no defaults available, data is already full (not delta)
            if not next(defaults) then
                fullModules[moduleId] = moduleData
            else
                fullModules[moduleId] = PIE:DeltaDecode(moduleData, defaults)
            end
        end
    else
        fullModules = parsed.modules or {}
    end
    
    -- Return in profile format
    return {
        modules = fullModules,
        enabled = parsed.enabled or {},
        -- Container positions (usually empty for defaults)
        uiFrameContainerPositions = parsed.uiFrameContainerPositions or {},
        actionBarContainerPositions = parsed.actionBarContainerPositions or {},
        cooldowns = parsed.cooldowns or {},
        buffHighlights = parsed.buffHighlights or {},
        -- Store source resolution for scale adjustment
        importedFrom = {
            screenWidth = parsed._meta.screenWidth,
            screenHeight = parsed._meta.screenHeight,
            uiScale = parsed._meta.uiScale,
        },
    }
end

-- Initialize/decode all profiles
function DefaultProfiles:Initialize()
    if initialized then return end
    
    TweaksUI:PrintDebug("DefaultProfiles: Initializing...")
    
    -- Decode each profile's export string
    for name, definition in pairs(PROFILE_DEFINITIONS) do
        if definition.exportString and definition.exportString ~= "" then
            local decoded = DecodeExportString(definition.exportString)
            if decoded then
                decodedProfiles[name] = {
                    definition = definition,
                    data = decoded,
                }
                TweaksUI:PrintDebug("DefaultProfiles: Loaded '" .. name .. "'")
            else
                TweaksUI:PrintDebug("DefaultProfiles: Failed to decode '" .. name .. "'")
            end
        end
    end
    
    initialized = true
    TweaksUI:PrintDebug("DefaultProfiles: Initialized with " .. self:GetCount() .. " profiles")
end

-- Check if a profile name is a built-in default
function DefaultProfiles:IsDefaultProfile(name)
    return decodedProfiles[name] ~= nil
end

-- Get a decoded profile by name (returns profile data or nil)
function DefaultProfiles:GetProfile(name)
    local profile = decodedProfiles[name]
    if profile then
        return profile.data, profile.definition
    end
    return nil, nil
end

-- Get definition (metadata) for a profile
function DefaultProfiles:GetDefinition(name)
    local profile = decodedProfiles[name]
    if profile then
        return profile.definition
    end
    -- Also return definition even if not decoded (for UI purposes)
    return PROFILE_DEFINITIONS[name]
end

-- Get list of available default profiles (only those with valid export strings)
function DefaultProfiles:GetProfileList()
    local list = {}
    
    for name, profile in pairs(decodedProfiles) do
        local def = profile.definition
        table.insert(list, {
            name = name,
            description = def.description,
            icon = def.icon,
            iconCoords = def.iconCoords,
            category = def.category,
            order = def.order,
            isBuiltIn = true,
        })
    end
    
    -- Sort by order, then name
    table.sort(list, function(a, b)
        if a.order ~= b.order then
            return (a.order or 999) < (b.order or 999)
        end
        return a.name < b.name
    end)
    
    return list
end

-- Get profiles by category
function DefaultProfiles:GetProfilesByCategory(category)
    local list = {}
    
    for name, profile in pairs(decodedProfiles) do
        local def = profile.definition
        if def.category == category then
            table.insert(list, {
                name = name,
                description = def.description,
                icon = def.icon,
                iconCoords = def.iconCoords,
                order = def.order,
                isBuiltIn = true,
            })
        end
    end
    
    -- Sort by order, then name
    table.sort(list, function(a, b)
        if a.order ~= b.order then
            return (a.order or 999) < (b.order or 999)
        end
        return a.name < b.name
    end)
    
    return list
end

-- Get count of available profiles
function DefaultProfiles:GetCount()
    local count = 0
    for _ in pairs(decodedProfiles) do
        count = count + 1
    end
    return count
end

-- Get all profile names (for protection checks)
function DefaultProfiles:GetAllNames()
    local names = {}
    -- Include all defined names, even if export string is empty
    -- This prevents users from creating profiles with these reserved names
    for name in pairs(PROFILE_DEFINITIONS) do
        table.insert(names, name)
    end
    return names
end

-- Force re-decode (useful if PIE wasn't ready at init)
function DefaultProfiles:Reload()
    decodedProfiles = {}
    initialized = false
    self:Initialize()
end
