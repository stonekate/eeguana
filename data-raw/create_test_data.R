library(eeguana)

data_sincos2id <- eeg_lst(
    signal_tbl = tibble::tibble(
                             X = sin(1:20),
                             Y = cos(1:20),
                             .id = rep(c(1L, 2L), each = 10),
                             .sample = sample_int(rep(seq(-4L, 5L), times = 2), sampling_rate = 500)
                         ),
    channels_tbl =
        dplyr::tibble(
                   .channel = c("X", "Y"), .reference = NA, theta = NA, phi = NA,
                   radius = NA, .x = NA_real_, .y = NA_real_, .z = NA_real_
               ),
    events_tbl = dplyr::tribble(
                            ~.id, ~.type, ~.description, ~.initial, ~.final, ~.channel,
                            1L, "New Segment", NA_character_, -4L, -4L, NA,
                            1L, "Bad", NA_character_, -2L, 0L, NA,
                            1L, "Time 0", NA_character_, 1L, 1L, NA,
                            1L, "Bad", NA_character_, 2L, 3L, "X",
                            2L, "New Segment", NA_character_, -4L, -4L, NA,
                            2L, "Time 0", NA_character_, 1L, 1L, NA,
                            2L, "Bad", NA_character_, 2L, 2L, "Y"
                        ),
    segments_tbl = dplyr::tibble(.id = c(1L, 2L), .recording = "recording1", segment = c(1L, 2L))
)

data_sincos2id_2 <- eeg_lst(
    signal_tbl = dplyr::tibble(
                            X = sin(1:20),
                            Y = cos(1:20),
                            .id = rep(c(1L, 2L), each = 10),
                            .sample = sample_int(rep(seq(-4L, 5L), times = 2),
                                                 sampling_rate = 500
                                                 )
                        ),
    channels_tbl = dplyr::tibble(
                              .channel = c("X", "Y"), .reference = NA, theta = NA, phi = NA,
                              radius = NA, .x = NA_real_, .y = NA_real_, .z = NA_real_
                          ),
    events_tbl = dplyr::tribble(
                            ~.id, ~.type, ~.description, ~.initial, ~.final, ~.channel,
                            1L, "New Segment", NA_character_, -4L, -4L, NA,
                            1L, "Bad", NA_character_, -2L, 0L, "X",
                            1L, "Bad", NA_character_, -2L, 0L, "Y",
                            1L, "Time 0", NA_character_, 1L, 1L, NA,
                            1L, "Bad", NA_character_, 2L, 3L, "X",
                            2L, "New Segment", NA_character_, -4L, -4L, NA,
                            2L, "Time 0", NA_character_, 1L, 1L, NA,
                            2L, "Bad", NA_character_, 2L, 2L, "Y"
                        ),
    segments_tbl = dplyr::tibble(.id = c(1L, 2L), .recording = "recording1", segment = c(1L, 2L))
)

usethis::use_data(data_sincos2id, data_sincos2id_2, internal = TRUE, overwrite = TRUE)