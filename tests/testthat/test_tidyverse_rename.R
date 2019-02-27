context("test tidyverse functions rename/select")
library(eeguana)


# create fake dataset
data_1 <- eeg_lst(
  signal = signal_tbl(
    signal_matrix = as.matrix(
      data.frame(X = sin(1:30), Y = cos(1:30))
    ),
    ids = rep(c(1L, 2L, 3L), each = 10),
    sample_ids = sample_int(rep(seq(-4L, 5L), times = 3), sampling_rate = 500),
    dplyr::tibble(
      channel = c("X", "Y"), .reference = NA, theta = NA, phi = NA,
      radius = NA, .x = c(1, 1), .y = NA_real_, .z = NA_real_
    )
  ),
  events = dplyr::tribble(
    ~.id, ~type, ~description, ~.sample_0, ~.size, ~.channel,
    1L, "New Segment", NA_character_, -4L, 1L, NA,
    1L, "Bad", NA_character_, -2L, 3L, NA,
    1L, "Time 0", NA_character_, 1L, 1L, NA,
    1L, "Bad", NA_character_, 2L, 2L, "X",
    2L, "New Segment", NA_character_, -4L, 1L, NA,
    2L, "Time 0", NA_character_, 1L, 1L, NA,
    2L, "Bad", NA_character_, 2L, 1L, "Y",
    3L, "New Segment", NA_character_, -4L, 1L, NA,
    3L, "Time 0", NA_character_, 1L, 1L, NA,
    3L, "Bad", NA_character_, 2L, 1L, "Y"
  ),
  segments = dplyr::tibble(.id = c(1L, 2L, 3L),
                           recording = "recording1",
                           segment = c(1L, 2L, 3L),
                           condition = c("a", "b", "a"))
)

# just some different X and Y
data_2 <- mutate(data_1, recording = "recording2",
                 X = sin(X + 10),
                 Y = cos(Y - 10),
                 condition = c("b", "a", "b"))

# bind it all together
data <- bind(data_1, data_2)

# for checks later
reference_data <- data.table::copy(data)



###############################################
################ test rename ##################
###############################################


test_that("internal (?) variables cannot be renamed", {
  expect_error(rename(data, ID = .id))
  expect_error(rename(data, time = .sample_id))
  expect_error(rename(data, time = .sample_0))
  expect_error(rename(data, length = .size))
  expect_error(rename(data, electrode = .channel))
})


### signal table

rename1_eeg <- rename(data, ZZ = Y) 
rename1_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(ZZ = Y) 


rename2_eeg <- rename(data, x = X)
rename2_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(x = X) 


test_that("renaming in signal table doesn't change data", {
  # in signal table
  expect_equivalent(rename1_eeg$signal, data$signal)
  expect_equivalent(rename2_eeg$signal, data$signal)
  expect_equal(as.matrix(rename1_eeg$signal[, c(".id", ".sample_id")]), 
               as.matrix(data$signal[, c(".id", ".sample_id")]))
  expect_equal(as.matrix(rename2_eeg$signal[, c(".id", ".sample_id")]), 
               as.matrix(data$signal[, c(".id", ".sample_id")]))
  # in segments table
  expect_equal(rename1_eeg$segments, data$segments)
  expect_equal(rename2_eeg$segments, data$segments)
})


test_that("events table is correct after rename", {
  # events haven't changed
  expect_equal(rename1_eeg$events, data$events)
  expect_equal(rename2_eeg$events, data$events)
  # new names are added
  expect_true(nrow(filter(rename1_eeg$events, .channel == "Y")) == 0)
  expect_true(nrow(filter(rename1_eeg$events, .channel == "ZZ")) > 0)
  expect_true(nrow(filter(rename2_eeg$events, .channel == "X")) == 0)
  expect_true(nrow(filter(rename2_eeg$events, .channel == "x")) > 0)
})


test_that("rename works the same on eeg_lst as on tibble", {
  expect_setequal(as.matrix(rename1_eeg$signal[, c("X", "ZZ")]), 
               as.matrix(select(rename1_tbl, X, ZZ)))
  expect_setequal(as.matrix(rename2_eeg$signal[, c("x", "Y")]), 
               as.matrix(select(rename2_tbl, x, Y)))
})


test_that("the classes of channels of signal_tbl haven't changed", {
  expect_equal(is_channel_dbl(rename1_eeg$signal$X), TRUE)
  expect_equal(is_channel_dbl(rename2_eeg$signal$Y), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})


### segments table

rename3_eeg <- rename(data, subject = recording)
rename3_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(subject = recording)


rename4_eeg <- rename(data, epoch = segment)
rename4_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(epoch = segment)


rename5_eeg <- rename(data, cond = condition)
rename5_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(cond = condition)


test_that("renaming in segments table doesn't change data", {
  # in signal table
  expect_equal(rename3_eeg$signal, data$signal)
  expect_equal(rename4_eeg$signal, data$signal)
  expect_equal(rename5_eeg$signal, data$signal)
  # in events table
  expect_equal(rename3_eeg$events, data$events)
  expect_equal(rename4_eeg$events, data$events)
  expect_equal(rename5_eeg$events, data$events)
  # in segements table
  expect_equal(as.matrix(select(rename3_eeg$segments, -subject)), 
               as.matrix(select(data$segments, -recording)))
  expect_equal(as.matrix(select(rename4_eeg$segments, -epoch)), 
               as.matrix(select(data$segments, -segment)))  
  expect_equal(as.matrix(select(rename5_eeg$segments, -cond)), 
               as.matrix(select(data$segments, -condition)))  
  expect_equal(as.character(rename3_eeg$segments$subject),
               as.character(data$segments$recording))
  # equivalent only works for numerical data
  expect_equivalent(rename4_eeg$segments$epoch, 
                    data$segments$segment)
  expect_equal(as.character(rename5_eeg$segments$cond),
               as.character(data$segments$condition))
})


test_that("rename works the same on eeg_lst as on tibble", {
  expect_setequal(as.matrix(rename3_eeg$segments), 
               as.matrix(select(rename3_tbl, .id, subject, segment, condition)))
  expect_setequal(as.matrix(rename4_eeg$segments), 
                  as.matrix(select(rename4_tbl, .id, recording, epoch, condition)))
  expect_setequal(as.matrix(rename5_eeg$segments), 
                  as.matrix(select(rename5_tbl, .id, recording, segment, cond)))
})


test_that("the classes of channels of signal_tbl haven't changed", {
  expect_equal(is_channel_dbl(rename3_eeg$signal$X), TRUE)
  expect_equal(is_channel_dbl(rename4_eeg$signal$Y), TRUE)
  expect_equal(is_channel_dbl(rename5_eeg$signal$X), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})




### events table

rename6_eeg <- rename(data$events, label = type)
rename7_eeg <- rename(data$events, info = description)


test_that("renaming in events table doesn't change data", {
  expect_equal(select(rename6_eeg, .id, .sample_0, .size, .channel), 
               select(data$events, .id, .sample_0, .size, .channel))
  expect_equal(select(rename7_eeg, .id, .sample_0, .size, .channel), 
               select(data$events, .id, .sample_0, .size, .channel))
  expect_equal(as.character(rename6_eeg$label),
               as.character(data$events$type))
  expect_equal(as.character(rename7_eeg$info),
               as.character(data$events$description))
})



### other renames

# rename_if(data, is_character, tolower) # deprecated

# these only seem to change the signal table
rename_all1_eeg <- rename_all(data, toupper)
rename_all1_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename_all(toupper)


rename_all2_eeg <- rename_all(data, tolower)
rename_all2_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename_all(tolower)



test_that("scoped renaming doesn't change data", {
  # in signal table
  expect_equivalent(rename_all1_eeg$signal, data$signal)
  expect_equivalent(rename_all2_eeg$signal, data$signal)
  expect_setequal(as.matrix(rename_all1_eeg$signal[, c("X", "Y")]),
                  as.matrix(select(rename_all1_tbl, X, Y)))
  expect_setequal(as.matrix(rename_all2_eeg$signal[, c("x", "y")]),
                  as.matrix(select(rename_all2_tbl, x, y)))
  # in segments table
  expect_equivalent(rename_all1_eeg$segments, data$segments)
  expect_equivalent(rename_all2_eeg$segments, data$segments)
  expect_setequal(as.matrix(rename_all1_eeg$segments),
                  as.matrix(select(rename_all1_tbl, .ID, RECORDING, SEGMENT, CONDITION)))
  expect_setequal(as.matrix(rename_all2_eeg$segments),
                  as.matrix(select(rename_all2_tbl, .id, recording, segment, condition)))
  # in events table
  expect_equal(rename_all1_eeg$events, data$events)
  # uh oh
  expect_equal(rename_all2_eeg$events, data$events)
})


test_that("the classes of channels of signal_tbl haven't changed", {
  expect_equal(is_channel_dbl(rename_all1_eeg$signal$X), TRUE)
  expect_equal(is_channel_dbl(rename_all2_eeg$signal$x), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})




###################################################################
################# rename on new variables #########################
###################################################################

rename_select_eeg <- rename(data, ZZ = Y) %>%
  select(ZZ)
rename_select_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::rename(ZZ = Y) %>%
  dplyr::select(ZZ)


mutate_rename_eeg <- mutate(data, Z = Y + 1) %>%
  rename(ZZ = Z)
mutate_rename_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::mutate(Z = Y + 1) %>%
  dplyr::rename(ZZ = Z)



test_that("rename on new variables doesn't change data", {
  # in signal table
  expect_equal(rename_select_eeg$signal[, c(".id", ".sample_id")],
               data$signal[, c(".id", ".sample_id")])
  expect_equal(mutate_rename_eeg$signal[, c(".id", ".sample_id")],
               data$signal[, c(".id", ".sample_id")])
  expect_equivalent(rename_select_eeg$signal$ZZ, data$signal$Y)
  expect_equivalent(mutate_rename_eeg$signal$ZZ, data$signal$Y+1)
  # in segments table
  expect_equal(rename_select_eeg$segments, data$segments)
  expect_equal(mutate_rename_eeg$segments, data$segments)
})


test_that("select on new variables removes the right data from events", {
  # but should the old channel now have the new name?
  expect_true(nrow(filter(rename_select_eeg$events, .channel == "X")) == 0)
  expect_true(nrow(filter(rename_select_eeg$events, .channel == "ZZ")) > 0)
  # should the events table get larger with the new "channel"?
  expect_equal(mutate_rename_eeg$events, data$events)
})


test_that("select works the same on eeg_lst as on tibble", {
  expect_setequal(as.matrix(rename_select_eeg$signal$ZZ),
                  as.matrix(rename_select_tbl))
  expect_setequal(as.matrix(mutate_rename_eeg$signal[, !c(".sample_id")]),
                  as.matrix(select(mutate_rename_tbl, .id, X, Y, ZZ))) 
  expect_setequal(as.matrix(mutate_rename_eeg$segments),
                  as.matrix(select(mutate_rename_tbl, .id, recording, segment, condition)))
})



test_that("the classes of channels of signal_tbl haven't changed", {
  expect_equal(is_channel_dbl(rename_select_eeg$signal$ZZ), TRUE)
  expect_equal(is_channel_dbl(mutate_rename_eeg$signal$X), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})



### with grouping

# strange warning message for grouping by segment table vars only: 
# Grouping variables are missing.
group_rename_eeg <- data %>%
  group_by(recording) %>%
  rename(subject = recording)

group_rename_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::group_by(recording) %>%
  dplyr::rename(subject = recording)


group_rename_summarize_eeg <- data %>%
  group_by(recording, condition) %>%
  summarize_all_ch(mean) %>%
  rename(subject = recording)

group_rename_summarize_tbl <- data %>%
  as_tibble() %>%
  tidyr::spread(key = channel, value = amplitude) %>%
  dplyr::group_by(recording, condition) %>%
  dplyr::summarise(X = mean(X), Y = mean(Y)) %>%
  dplyr::rename(subject = recording)


test_that("rename on grouped variables doesn't change data", {
  # in the signal table
  expect_equal(group_rename_eeg$signal, data$signal)
  # in the segments table
  expect_equal(select(group_rename_eeg$segments, -subject), 
               select(data$segments, -recording))
  expect_equal(as.character(group_rename_eeg$segments$subject),
               as.character(data$segments$recording))
})


test_that("rename on grouped variable removes the right events data", {
  expect_equal(group_rename_eeg$events, data$events)
})


test_that("rename on group vars works same in eeg_lst and tibble", {
  expect_setequal(as.matrix(group_rename_eeg$signal[, !c(".sample_id")]),
                  as.matrix(group_rename_tbl[, c(".id", "X", "Y")]))
  expect_setequal(as.matrix(group_rename_eeg$segments),
                  as.matrix(select(group_rename_tbl, .id, subject, segment, condition)))  
  expect_setequal(as.matrix(group_rename_summarize_eeg$signal[, c("X", "Y")]),
                  as.matrix(group_rename_summarize_tbl[, c("X", "Y")]))
  expect_setequal(as.matrix(group_rename_summarize_eeg$segments[, c("subject", "condition")]),
                  as.matrix(group_rename_summarize_tbl[, c("subject", "condition")]))
})


test_that("the classes of channels of signal_tbl haven't changed", {
  expect_equal(is_channel_dbl(group_rename_eeg$signal$X), TRUE)
  expect_equal(is_channel_dbl(group_rename_summarize_eeg$signal$X), TRUE)
})


# check against original data
test_that("data didn't change", {
  expect_equal(reference_data, data)
})