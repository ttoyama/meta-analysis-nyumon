# 200_part2.R  第2部の解析（本用の短い版）
library(mada)
library(lme4)
library(meta)

pct <- read.csv("data/pct_bact.csv",
                fileEncoding = "UTF-8")

# 全 10 研究: 研究ごとの感度と特異度
d <- madad(pct, correction.control = "single")
print(d, digits = 2)

# 主解析: カットオフ 0.5 ng/mL の 6 研究
pct5 <- subset(pct, cutoff == 0.5)

# 二項 GLMM 用の縦長データ。1 研究を 2 行にする
to_long <- function(d) rbind(
  data.frame(study = d$study, sens = 1, spec = 0,
             y = d$TP, n = d$TP + d$FN),
  data.frame(study = d$study, sens = 0, spec = 1,
             y = d$TN, n = d$TN + d$FP))
long5 <- to_long(pct5)

# 二変量モデル（相関を推定する）
g2 <- glmer(cbind(y, n - y) ~ 0 + sens + spec +
              (0 + sens + spec | study),
            data = long5, family = binomial)
summary(g2)    # 相関が -1 になり、singular の警告が出る

# 相関を 0 にしたモデル（ハンドブック 10.6.2）
g <- glmer(cbind(y, n - y) ~ 0 + sens + spec +
             (0 + sens | study) + (0 + spec | study),
           data = long5, family = binomial)
summary(g)

# 要約点と 95% 信頼区間
b <- fixef(g)
V <- as.matrix(vcov(g))
se_b <- sqrt(diag(V))
plogis(cbind(est = b, lower = b - 1.96 * se_b,
             upper = b + 1.96 * se_b))

# 尤度比と診断オッズ比（要約点から導く）
se <- unname(plogis(b["sens"]))
sp <- unname(plogis(b["spec"]))
c(LRpos = se / (1 - sp), LRneg = (1 - se) / sp,
  DOR = (se / (1 - se)) / ((1 - sp) / sp))

# 参考: 正規近似の二変量モデル（mada）
summary(reitsma(pct5))

# 要約点、95% 信頼領域、95% 予測領域の図
ellipse_roc <- function(mu, S, n = 200) {
  r <- sqrt(qchisq(0.95, 2))
  th <- seq(0, 2 * pi, length.out = n)
  e <- t(mu + r * t(chol(S)) %*% rbind(cos(th), sin(th)))
  data.frame(fpr = plogis(e[, 2]), sens = plogis(e[, 1]))
}
vc <- VarCorr(g)
S_btw <- diag(c(attr(vc[[1]], "stddev")^2,
                attr(vc[[2]], "stddev")^2))
mu <- c(b["sens"], -b["spec"])   # logit 感度、logit 偽陽性割合
V_m <- matrix(c(V[1, 1], -V[1, 2], -V[1, 2], V[2, 2]), 2)
conf <- ellipse_roc(mu, V_m)
pred <- ellipse_roc(mu, S_btw + V_m)
pdf("fig_summary05.pdf", width = 5, height = 5, family = "Japan1GothicBBB")   # 日本語を書く
plot(NA, xlim = c(0, 1), ylim = c(0, 1),
     xlab = "1 - 特異度（偽陽性割合）", ylab = "感度")
abline(0, 1, lty = 3)
polygon(pred$fpr, pred$sens, border = "grey50", lty = 2)
polygon(conf$fpr, conf$sens, border = "black")
points(fpr(pct5), sens(pct5), pch = 21)
points(1 - sp, se, pch = 23, bg = "red", cex = 1.5)
dev.off()

# 全 10 研究: SROC 曲線（曲線だけを描き、要約点は使わない）
fit_all <- reitsma(pct)
summary(fit_all)
pdf("fig_sroc.pdf", width = 5, height = 5, family = "Japan1GothicBBB")   # 日本語を書く
plot(NA, xlim = c(0, 1), ylim = c(0, 1),
     xlab = "1 - 特異度（偽陽性割合）", ylab = "感度")
abline(0, 1, lty = 3)
lines(sroc(fit_all), lwd = 2)
points(fpr(pct), sens(pct), pch = 21)
dev.off()

# 共変量: log(カットオフ)（第 14 章）
pct$lcut <- log(pct$cutoff)
summary(reitsma(pct,
  formula = cbind(tsens, tfpr) ~ lcut))

# 実データ: AUDIT-C
data("AuditC")
summary(reitsma(AuditC))
ac <- as.data.frame(AuditC)
ac$study <- seq_len(nrow(ac))
ga <- glmer(cbind(y, n - y) ~ 0 + sens + spec +
              (0 + sens + spec | study),
            data = to_long(ac), family = binomial)
summary(ga)
plogis(fixef(ga))
