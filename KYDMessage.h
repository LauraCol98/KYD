#ifndef KEEPYOURDISTANCE_H
#define KEEPYOURDISTANCE_H

// Message structure : DATA
typedef nx_struct radio_msg {
  nx_uint16_t identifier;
} radioMessage;

// Default setting
enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif