
add_executable(lut_circuit_test lut_circuit_test.cpp common/lut_circuit.cpp)
target_link_libraries(lut_circuit_test ABY::aby ENCRYPTO_utils::encrypto_utils)
