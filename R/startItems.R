startItems<-function (itemBank, model = NULL, fixItems = NULL, seed = NULL, 
    nrItems = 1, theta = 0, D = 1, randomesque = 1, random.seed = NULL, 
    startSelect = "MFI", nAvailable = NULL, cbControl = NULL, 
    cbGroup = NULL, random.cb = NULL) 
{
    if (!is.null(nAvailable)) {
        if (length(nAvailable) != nrow(itemBank)) 
            stop("mismatch between length of 'nAvailable' and the number of items in 'itemBank'", 
                call. = FALSE)
        if (sum(nAvailable) < nrItems) 
            stop("less available items (in 'nAvailable') than requested by 'nrItems'!", 
                call. = FALSE)
    }
    if (!is.null(cbControl)) {
        nr.it <- rep(0, length(cbControl$names))
        if (!is.null(random.cb)) 
            set.seed(random.cb)
        for (i in 1:nrItems) {
            if (sum(nr.it) == 0) 
                emp.prop <- nr.it
            else emp.prop <- nr.it/sum(nr.it)
            if (min(emp.prop) == 0) 
                allow <- which(emp.prop == 0)
            else allow <- 1:length(nr.it)
            grs <- which((cbControl$props[allow] - emp.prop[allow]) == 
                max(cbControl$props[allow] - emp.prop[allow]))
            GR <- ifelse(length(grs) > 1, sample(allow[grs], 
                1), allow[grs])
            nr.it[GR] <- nr.it[GR] + 1
        }
        set.seed(NULL)
    }
    if (nrItems > 0) 
        if (startSelect == "progressive" | startSelect == "proportional") {
            fixItems <- NULL
            nrItems <- 1
            seed <- NA
        }
    if (!is.null(fixItems)) {
        items <- fixItems
        par <- itemBank[fixItems, ]
        thStart <- startSelect <- NA
        res <- list(items = items, par = par, thStart = thStart, 
            startSelect = startSelect,names=NULL)
    }
    else {
        if (nrItems > 0) {
            if (!is.null(seed)) {
                if (!is.na(seed)) 
                  set.seed(seed)
                if (is.null(cbControl)) {
                  if (is.null(nAvailable)) 
                    items <- sample(1:nrow(itemBank), nrItems)
                  else items <- sample(which(nAvailable == 1), 
                    nrItems)
                }
                else {
                  items <- NULL
                  if (is.null(nAvailable)) 
                    nAv <- rep(1, nrow(itemBank))
                  else nAv <- nAvailable
                  for (i in 1:length(nr.it)) {
                    if (nr.it[i] > 0) 
                      items <- c(items, sample(which(nAv == 1 & 
                        cbGroup == cbControl$names[i]), nr.it[i], 
                        replace = FALSE))
                  }
                }
                par <- itemBank[items, ]
                thStart <- startSelect <- NA
                set.seed(NULL)
            }
            else {
                thStart <- theta
                if (startSelect != "bOpt" & startSelect != "thOpt" & 
                  startSelect != "MFI" & startSelect != "progressive" & 
                  startSelect != "proportional") 
                  stop("'startSelect' must be either 'bOpt', 'thOpt', 'progressive', 'proportional' or 'MFI'", 
                    call. = FALSE)
                if (!is.null(model) & startSelect != "MFI") 
                  stop("'startSelect' can only be 'MFI' with polytomous items!", 
                    call. = FALSE)
                if (startSelect == "bOpt") {
                  items = NULL
                  nr.items <- nrow(itemBank)
                  selected <- rep(0, nr.items)
                  if (!is.null(random.seed)) 
                    set.seed(random.seed)
                  for (i in 1:length(thStart)) {
                    item.dist <- abs(thStart[i] - itemBank[, 
                      2])
                    if (!is.null(nAvailable)) 
                      pos.adm <- (1 - selected) * nAvailable
                    else pos.adm <- 1 - selected
                    pr <- sort(item.dist[pos.adm == 1])
                    keep <- pr[randomesque]
                    prov <- which(pos.adm == 1 & item.dist <= 
                      keep)
                    items[i] <- ifelse(length(prov) == 1, prov, 
                      sample(prov, 1))
                    selected[items[i]] <- 1
                  }
                }
                if (startSelect == "thOpt") {
                  items = NULL
                  nr.items <- nrow(itemBank)
                  selected <- rep(0, nr.items)
                  u <- -3/4 + (itemBank[, 3] + itemBank[, 4] + 
                    -2 * itemBank[, 3] * itemBank[, 4])/2
                  v <- (itemBank[, 3] + itemBank[, 4] - 1)/4
                  xstar <- 2 * sqrt(-u/3) * cos(acos(-v * sqrt(-27/u^3)/2)/3 + 
                    4 * pi/3) + 1/2
                  thMax <- itemBank[, 2] + log((xstar - itemBank[, 
                    3])/(itemBank[, 4] - xstar))/(D * itemBank[, 
                    1])
                  if (!is.null(random.seed)) 
                    set.seed(random.seed)
                  for (i in 1:length(thStart)) {
                    item.dist <- abs(thMax - thStart[i])
                    if (!is.null(nAvailable)) 
                      pos.adm <- (1 - selected) * nAvailable
                    else pos.adm <- 1 - selected
                    pr <- sort(item.dist[pos.adm == 1])
                    keep <- pr[randomesque]
                    prov <- which(pos.adm == 1 & item.dist <= 
                      keep)
                    items[i] <- ifelse(length(prov) == 1, prov, 
                      sample(prov, 1))
                    selected[items[i]] <- 1
                  }
                }
                if (startSelect == "MFI") {
                  items = NULL
                  nr.items <- nrow(itemBank)
                  selected <- rep(0, nr.items)
                  if (!is.null(random.seed)) 
                    set.seed(random.seed)
                  for (i in 1:length(thStart)) {
                    item.info <- Ii(thStart[i], itemBank, model = model, 
                      D = D)$Ii
                    if (!is.null(nAvailable)) 
                      pos.adm <- (1 - selected) * nAvailable
                    else pos.adm <- 1 - selected
                    pr <- sort(item.info[pos.adm == 1], decreasing = TRUE)
                    keep <- pr[randomesque]
                    prov <- which(pos.adm == 1 & item.info >= 
                      keep)
                    items[i] <- ifelse(length(prov) == 1, prov, 
                      sample(prov, 1))
                    selected[items[i]] <- 1
                  }
                }
                par = itemBank[items, ]
            }
            res <- list(items = items, par = par, thStart = thStart, 
                startSelect = startSelect,names=NULL)
        }
        else res <- list(items = NULL, par = NULL, thStart = NULL, 
            startSelect = NULL,names=NULL)
    }
if (!is.null(row.names(itemBank))) res$names<-row.names(itemBank)[res$items]
    set.seed(NULL)
    return(res)
}
