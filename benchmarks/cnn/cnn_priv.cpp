typedef char Scalar;

// dimensions
#define WIDTH 8
#define HEIGHT WIDTH
#define INPUTS (WIDTH*HEIGHT)

#define CONV1_KERNEL_SIZE 3

#define OUTPUTS 10

// resulting configuration
#define CONV1_IN_WIDTH WIDTH
#define CONV1_IN_HEIGHT HEIGHT
#define CONV1_INPUTS (CONV1_IN_WIDTH*CONV1_IN_HEIGHT)
#define CONV1_OUT_WIDTH (WIDTH-1)
#define CONV1_OUT_HEIGHT (HEIGHT-1)
#define CONV1_OUTPUTS ((CONV1_OUT_WIDTH)*(CONV1_OUT_HEIGHT))
#define CONV1_KERNEL_END (CONV1_KERNEL_SIZE/2)
#define CONV1_KERNEL_START (-CONV1_KERNEL_END)
#define CONV1_WEIGHTS (CONV1_KERNEL_SIZE*CONV1_KERNEL_SIZE)

#define FC1_INPUTS CONV1_OUTPUTS
#define FC1_OUTPUTS OUTPUTS
#define FC1_WEIGHTS (FC1_INPUTS*FC1_OUTPUTS)

// layer inputs and outputs

struct Conv1In {
  Scalar values[CONV1_INPUTS];
  Scalar weights[CONV1_WEIGHTS];
};

struct Conv1Out {
  Scalar values[CONV1_OUTPUTS];
};

struct FC1In {
  Scalar values[FC1_INPUTS];
  Scalar weights[FC1_WEIGHTS];
};

struct FC1Out {
  Scalar values[FC1_OUTPUTS];
};

// network inputs and outputs

struct Input {
  Scalar inputs[INPUTS];
  Scalar conv1_weights[CONV1_WEIGHTS];
  Scalar fc1_weights[FC1_WEIGHTS];
};

struct Output {
  Scalar values[OUTPUTS];
};

// non-parametric layers

Scalar relu(Scalar x) {
  if (x > 0) return x; else return 0;
}

// parametric layers

Conv1Out conv1(Conv1In in) {
  Conv1Out result;

#pragma hls_unroll yes
  for (int y = 0; y < CONV1_OUT_HEIGHT; y++) {
#pragma hls_unroll yes
    for (int x = 0; x < CONV1_OUT_WIDTH; x++) {
      int idx = y * CONV1_OUT_HEIGHT + x;
      result.values[idx] = 0;

#pragma hls_unroll yes
      for (int k_y = 0, offset_y = CONV1_KERNEL_START; k_y < CONV1_KERNEL_SIZE; k_y++, offset_y++) {
#pragma hls_unroll yes
        for (int k_x = 0, offset_x = CONV1_KERNEL_START; k_x < CONV1_KERNEL_SIZE; k_x++, offset_x++) {
          int in_x = (x + 1) + offset_x;
          int in_y = (y + 1) + offset_y;
          result.values[idx] += in.values[in_y * CONV1_IN_HEIGHT + in_x] * in.weights[k_y * CONV1_KERNEL_SIZE + k_x];
        }
      }
    }
  }

  return result;
}

FC1Out fc1(FC1In in) {
  FC1Out result;

#pragma hls_unroll yes
  for (int i = 0; i < FC1_OUTPUTS; i++) {
    result.values[i] = 0;

#pragma hls_unroll yes
    for (int j = 0; j < FC1_INPUTS; j++) {
      result.values[i] += in.values[j] * in.weights[j + i * FC1_OUTPUTS];
    }
  }

  return result;
}

// network

#pragma spfe_private
Output forward(Input in) {
  Output result;
  Conv1In conv1_in;
  FC1In fc1_in;

  // load weights
#pragma hls_unroll yes
  for (int i = 0; i < CONV1_WEIGHTS; i++) conv1_in.weights[i] = in.conv1_weights[i];

#pragma hls_unroll yes
  for (int i = 0; i < FC1_WEIGHTS; i++) fc1_in.weights[i] = in.fc1_weights[i];

  // perform forward pass
#pragma hls_unroll yes
  for (int i = 0; i < CONV1_INPUTS; i++) conv1_in.values[i] = in.inputs[i];

  Conv1Out conv1_out = conv1(conv1_in);

#pragma hls_unroll yes
  for (int i = 0; i < FC1_INPUTS; i++) fc1_in.values[i] = relu(conv1_out.values[i]);

  FC1Out fc1_out = fc1(fc1_in);

#pragma hls_unroll yes
  for (int i = 0; i < FC1_OUTPUTS; i++) result.values[i] = relu(fc1_out.values[i]);

  return result;
}

Output network(Input in) {
  return forward(in);
}
