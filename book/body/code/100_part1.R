# 100_part1.R  第1部の解析
library(meta)
library(metafor)

bp <- read.csv("data/bp_stroke.csv",
               fileEncoding = "UTF-8")

# 主解析: リスク比、ランダム効果（REML）、予測区間つき
m <- metabin(ev_t, n_t, ev_c, n_c, studlab = study,
             data = bp, sm = "RR", method = "Inverse",
             method.tau = "REML", prediction = TRUE)
summary(m)

update(m, method = "MH")              # MH 法（固定効果）
update(m, method.random.ci = "HK")    # Hartung-Knapp 調整
m_sub <- update(m, subgroup = pop)    # 対象集団別
m_sub
update(m, subgroup = rob)             # バイアスのリスク別
update(m, subset = rob != "高")       # 感度分析
metainf(m, pooled = "random")         # 1 試験ずつ除く
metabias(m, method.bias = "Egger", k.min = 10)
summary(m)                            # 固定効果とランダム効果の統合値を並べて比べる

# 図（PDF に保存する）
pdf("fig_forest.pdf", width = 7, height = 4.5)
forest(m, sortvar = TE)
dev.off()
pdf("fig_funnel.pdf", width = 5.5, height = 4.5)
funnel(m, common = FALSE)
dev.off()

# 絶対効果: 対照群リスク 5% と 10% の 1000 人あたり
rr <- exp(c(m$TE.random, m$lower.random,
            m$upper.random))
1000 * 0.05 * (rr - 1)
1000 * 0.10 * (rr - 1)

# 実データ: BCG ワクチン（metadat::dat.bcg）
dat <- escalc(measure = "RR", ai = tpos, bi = tneg,
              ci = cpos, di = cneg, data = dat.bcg)
r0 <- rma(yi, vi, data = dat, method = "REML")
r0
predict(r0, transf = exp)
r1 <- rma(yi, vi, mods = ~ ablat, data = dat,
          method = "REML")              # 緯度でメタ回帰
r1
predict(r1, newmods = c(20, 40, 55), transf = exp)
