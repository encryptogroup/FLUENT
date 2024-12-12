struct categorize_car_inputs {
  uint8_t INPUT_A_hsn;
  uint16_t INPUT_A_tsn;
  uint8_t INPUT_A_firstlic;
  uint8_t INPUT_A_takerlic;
};

struct categorize_car_result {
  uint16_t OUTPUT_price;
  uint16_t OUTPUT_catcar;
};
