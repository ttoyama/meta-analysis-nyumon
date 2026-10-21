# 010_make_data.R  架空データを作る
# 乱数の種を固定しているので、何度実行しても同じ値になる

set.seed(20261021)

# ---- 第1部: 降圧薬 A 対 プラセボ（脳卒中）----
k <- 10
study <- c("Aoki 2009", "Berger 2011", "Chen 2012",
           "Dubois 2014", "Endo 2015", "Fischer 2016",
           "Garcia 2018", "Hayashi 2019", "Ivanov 2021",
           "Jensen 2022")
n_per_arm <- c(150, 1200, 420, 2500, 90, 800, 1600,
               300, 3000, 650)
pop <- c("高齢者", "一般", "高齢者", "一般", "高齢者",
         "一般", "高齢者", "一般", "一般", "高齢者")
p_ctrl <- ifelse(pop == "高齢者", 0.10, 0.05) *
  runif(k, 0.8, 1.2)
log_rr <- rnorm(k, log(0.80), 0.12)
log_rr[5] <- log(0.40)  # 小さな試験の大きな効果
ev_c <- rbinom(k, n_per_arm, p_ctrl)
ev_t <- rbinom(k, n_per_arm,
               pmin(p_ctrl * exp(log_rr), 0.9))
rob <- c("懸念あり", "低", "懸念あり", "低", "高",
         "低", "低", "懸念あり", "低", "低")
bp <- data.frame(study, pop, rob, ev_t, n_t = n_per_arm,
                 ev_c, n_c = n_per_arm)
write.csv(bp, "data/bp_stroke.csv", row.names = FALSE,
          fileEncoding = "UTF-8")

# ---- 第2部: PCT による菌血症の診断 ----
k2 <- 10
study2 <- c("Kato 2010", "Lopez 2011", "Mori 2013",
            "Nguyen 2014", "Ono 2015", "Park 2016",
            "Qureshi 2018", "Rossi 2019", "Sato 2021",
            "Tanaka 2023")
setting <- c("救急外来", "救急外来", "ICU", "救急外来",
             "ICU", "救急外来", "ICU", "救急外来", "ICU",
             "救急外来")
cutoff <- c(0.5, 0.5, 2.0, 0.25, 1.0, 0.5, 2.0, 0.5,
            1.0, 0.25)
n_pos <- c(45, 62, 38, 80, 51, 24, 70, 33, 58, 95)
n_neg <- c(310, 420, 140, 520, 190, 150, 230, 260,
           210, 640)
# カットオフが高いほど感度が下がり、特異度が上がる
shift <- log(cutoff / 0.5)
mu_se <- qlogis(0.78) - 0.55 * shift
mu_sp <- qlogis(0.74) + 0.55 * shift
r <- -0.4 * 0.45 * 0.55
S <- matrix(c(0.45^2, r, r, 0.55^2), 2)
re <- MASS::mvrnorm(k2, c(0, 0), S)
se <- plogis(mu_se + re[, 1])
sp <- plogis(mu_sp + re[, 2])
TP <- rbinom(k2, n_pos, se); FN <- n_pos - TP
TN <- rbinom(k2, n_neg, sp); FP <- n_neg - TN
# Mori 2013 と Qureshi 2018 をカットオフ 0.5 の研究に
# して数を引き直す（要約点を 0.5 の 6 研究で出すため）
set.seed(20261022)
redo <- match(c("Mori 2013", "Qureshi 2018"), study2)
cutoff[redo] <- 0.5
se_r <- plogis(qlogis(0.78) + c(-0.15, 0.55) +
                 rnorm(2, 0, 0.2))
sp_r <- plogis(qlogis(0.74) + c(0.10, -0.20) +
                 rnorm(2, 0, 0.2))
TP[redo] <- rbinom(2, n_pos[redo], se_r)
FN[redo] <- n_pos[redo] - TP[redo]
TN[redo] <- rbinom(2, n_neg[redo], sp_r)
FP[redo] <- n_neg[redo] - TN[redo]
# QUADAS-2 の判定（第 12 章）: 患者選択、対象検査、
# 参照基準、フローとタイミング
q_pat  <- c("低", "低", "低", "低", "低", "不明",
            "低", "低", "低", "低")
q_idx  <- c("低", "低", "低", "低", "不明", "低",
            "低", "高", "低", "低")
q_ref  <- c("低", "低", "不明", "低", "低", "低",
            "低", "低", "低", "低")
q_flow <- c("低", "低", "低", "不明", "低", "低",
            "高", "低", "低", "低")
pct <- data.frame(study = study2, setting, cutoff,
                  TP, FP, FN, TN,
                  q_pat, q_idx, q_ref, q_flow)
write.csv(pct, "data/pct_bact.csv", row.names = FALSE,
          fileEncoding = "UTF-8")
