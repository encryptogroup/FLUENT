
#include <stdint.h>
#include <stdio.h>
#include <time.h>

#include "categorize_car.priv.h"

// Manufacturer Prices & Encoding
// Opel: 50, Audi: 100, Mercedes: 250, Jaguar: 150
// 0XXX,    1XXX,     2XXX,         3XXX

#define PETROL 12
#define DIESEL 10
#define GAS 8
#define ELECTRO 16
#define HYBRID 14

// Power Type Prices & Encoding
// 20 + 2 * PS / 20
// XXXXY

// Car Categories
// 0: 0 - 50 PS
// 1: 51 - 100 PS
// 2: 101 - 150 PS
// 3: 151 - 200 PS
// 4: 201 - 250 PS
// 5: 251 - 300 PS
// 6: 301 - 350 PS
// 7: 351 - 400 PS
// 8: 401 - 450 PS
// 9: 451 - 500 PS
// 10: 501 - X PS

/**
 * Calculates a basic price and a categorization of the given car
 * @param INPUT_A_hsn number for manufacturer
 * @param INPUT_A_tsn number for specific car
 * @param INPUT_A_firstlic number of years since the car was first licensed
 * @param INPUT_A_takerlic number of years since the insurance taker has the license
 * @return OUTPUT_price the basic price of the car
 * @return OUTPUT_catcar a categorization of the car
 */
#pragma spfe_private
struct categorize_car_result mpc_main(struct categorize_car_inputs inputs) {
  uint8_t INPUT_A_hsn = inputs.INPUT_A_hsn;
  uint16_t INPUT_A_tsn = inputs.INPUT_A_tsn;
  uint8_t INPUT_A_firstlic = inputs.INPUT_A_firstlic;
  uint8_t INPUT_A_takerlic = inputs.INPUT_A_takerlic;

    uint16_t price = 0;
    uint8_t catcar = 0;

    switch (INPUT_A_hsn) {
        case 0: price += 50;
            switch (INPUT_A_tsn) {

                // Opel Corsa

                // 111: Opel Corsa 65 PS, Benzin
                case 111: price += PETROL + 28;
                    catcar = 1;
                    break;

                    // 112: Opel Corsa 75 PS, Benzin
                case 112: price += PETROL + 28;
                    catcar = 1;
                    break;

                    // 113: Opel Corsa 90 PS, Benzin
                case 113: price += PETROL + 30;
                    catcar = 1;
                    break;

                    // 114: Opel Corsa 150 PS, Benzin
                case 114: price += PETROL + 36;
                    catcar = 2;
                    break;

                    // 121: Opel Corsa 75 PS, Diesel
                case 121: price += DIESEL + 28;
                    catcar = 1;
                    break;

                    // 122: Opel Corsa 95 PS, Diesel
                case 122: price += DIESEL + 30;
                    catcar = 1;
                    break;

                    // 131: Opel Corsa 90 PS, Gas
                case 131: price += ELECTRO + 30;
                    catcar = 1;
                    break;

                    // Opel Ampera

                    // 211: Opel Ampera 54 PS, Benzin
                case 211: price += PETROL + 26;
                    catcar = 1;
                    break;

                    // 221: Opel Ampera 54 PS, Elektro
                case 221: price += ELECTRO + 26;
                    catcar = 1;
                    break;

                    // 231: Opel Ampera 54 PS, Hybrid
                case 231: price += HYBRID + 26;
                    catcar = 1;
                    break;

                    // 232: Opel Ampera 75 PS, Hybrid
                case 232: price += HYBRID + 28;
                    catcar = 1;
                    break;

                    // Opel Insignia

                    // 311: Opel Insignia 140 PS, Benzin
                case 311: price += PETROL + 34;
                    catcar = 2;
                    break;

                    // 312: Opel Insignia 165 PS, Benzin
                case 312: price += PETROL + 38;
                    catcar = 3;
                    break;

                    // 313: Opel Insignia 200 PS, Benzin
                case 313: price += PETROL + 40;
                    catcar = 3;
                    break;

                    // 314: Opel Insignia 325 PS, Benzin
                case 314: price += PETROL + 54;
                    catcar = 6;
                    break;

                    // 321: Opel Insignia 110 PS, Diesel
                case 321: price += DIESEL + 32;
                    catcar = 2;
                    break;

                    // 322: Opel Insignia 136 PS, Diesel
                case 322: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // 323: Opel Insignia 170 PS, Diesel
                case 323: price += DIESEL + 38;
                    catcar = 3;
                    break;

                    // 324: Opel Insignia 209 PS, Diesel
                case 324: price += DIESEL + 42;
                    catcar = 4;
                    break;
                    // 331: Opel Insignia 140 PS, Gas
                case 331: price += GAS + 34;
                    catcar = 2;
                    break;

                    // 332: Opel Insignia 220 PS, Gas
                case 332: price += GAS + 42;
                    catcar = 4;
                    break;

                    // Opel Zafira

                    // 411: Opel Zafira 120 PS, Benzin
                case 411: price += PETROL + 32;
                    catcar = 2;
                    break;

                    // 412: Opel Zafira 140 PS, Benzin
                case 412: price += PETROL + 34;
                    catcar = 2;
                    break;

                    // 413: Opel Zafira 170 PS, Benzin
                case 413: price += PETROL + 38;
                    catcar = 3;
                    break;

                    // 414: Opel Zafira 200 PS, Benzin
                case 414: price += PETROL + 40;
                    catcar = 3;
                    break;

                    // 421: Opel Zafira 120 PS, Diesel
                case 421: price += DIESEL + 32;
                    catcar = 2;
                    break;

                    // 422: Opel Zafira 131 PS, Diesel
                case 422: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // 423: Opel Zafira 136 PS, Diesel
                case 423: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // 424: Opel Zafira 170 PS, Diesel
                case 424: price += DIESEL + 38;
                    catcar = 3;
                    break;

                    // 431: Opel Zafira 140 PS, Gas
                case 431: price += GAS + 34;
                    catcar = 2;
                    break;

                    // 432: Opel Zafira 150 PS, Gas
                case 432: price += GAS + 36;
                    catcar = 2;
                    break;
            }
            break;
        case 1: price += 100;
            switch (INPUT_A_tsn) {

                // Audi A1

                // 111: Audi A1 82 PS, Benzin
                case 111: price += PETROL + 30;
                    catcar = 1;
                    break;

                    // 112: Audi A1 116 PS, Benzin
                case 112: price += PETROL + 32;
                    catcar = 2;
                    break;

                    // 113: Audi A1 150 PS, Benzin
                case 113: price += PETROL + 36;
                    catcar = 2;
                    break;

                    // 114: Audi A1 200 PS, Benzin
                case 114: price += PETROL + 36;
                    catcar = 3;
                    break;

                    // 121: Audi A1 90 PS, Diesel
                case 121: price += DIESEL + 30;
                    catcar = 1;
                    break;

                    // 122: Audi A1 116 PS, Diesel
                case 122: price += DIESEL + 32;
                    catcar = 2;
                    break;

                    // 123: Audi A1 136 PS, Diesel
                case 123: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // Audi TT

                    // 211: Audi TT 179 PS, Benzin
                case 211: price += PETROL + 38;
                    catcar = 3;
                    break;

                    // 212: Audi TT 230 PS, Benzin
                case 212: price += PETROL + 44;
                    catcar = 4;
                    break;

                    // 213: Audi TT 245 PS, Benzin
                case 213: price += PETROL + 46;
                    catcar = 4;
                    break;

                    // 214: Audi TT 310 PS, Benzin
                case 214: price += PETROL + 52;
                    catcar = 6;
                    break;

                    // 221: Audi TT 184 PS, Diesel
                case 221: price += DIESEL + 40;
                    catcar = 3;
                    break;

                    // Audi Q5

                    // 311: Audi Q5 245 PS, Benzin
                case 311: price += PETROL + 46;
                    catcar = 4;
                    break;

                    // 312: Audi Q5 249 PS, Benzin
                case 312: price += PETROL + 46;
                    catcar = 4;
                    break;

                    // 313: Audi Q5 252 PS, Benzin
                case 313: price += PETROL + 46;
                    catcar = 5;
                    break;

                    // 314: Audi Q5 354 PS, Benzin
                case 314: price += PETROL + 56;
                    catcar = 7;
                    break;

                    // 321: Audi Q5 136 PS, Diesel
                case 321: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // 322: Audi Q5 150 PS, Diesel
                case 322: price += DIESEL + 36;
                    catcar = 2;
                    break;

                    // 323: Audi Q5 190 PS, Diesel
                case 323: price += DIESEL + 40;
                    catcar = 3;
                    break;

                    // 324: Audi Q5 250 PS, Diesel
                case 324: price += DIESEL + 46;
                    catcar = 4;
                    break;

                    // 331: Audi Q5 245 PS, Elektro
                case 331: price += ELECTRO + 46;
                    catcar = 4;
                    break;

                    // 341: Audi Q5 245 PS, Hybrid
                case 341: price += HYBRID + 46;
                    catcar = 4;
                    break;

                    // Audi A8

                    // 411: Audi A8 252 PS, Benzin
                case 411: price += PETROL + 46;
                    catcar = 5;
                    break;

                    // 412: Audi A8 340 PS, Benzin
                case 412: price += PETROL + 54;
                    catcar = 6;
                    break;

                    // 413: Audi A8 500 PS, Benzin
                case 413: price += PETROL + 70;
                    catcar = 9;
                    break;

                    // 414: Audi A8 605 PS, Benzin
                case 414: price += PETROL + 82;
                    catcar = 10;
                    break;

                    // 421: Audi A8 211 PS, Diesel
                case 421: price += DIESEL + 42;
                    catcar = 4;
                    break;

                    // 422: Audi A8 286 PS, Diesel
                case 422: price += DIESEL + 50;
                    catcar = 5;
                    break;

                    // 431: Audi A8 286 PS, Elektro
                case 431: price += ELECTRO + 50;
                    catcar = 5;
                    break;

                    // 432: Audi A8 340 PS, Elektro
                case 432: price += ELECTRO + 54;
                    catcar = 6;
                    break;

                    // 441: Audi A8 286 PS, Hybrid
                case 441: price += HYBRID + 34;
                    catcar = 5;
                    break;

                    // 442: Audi A8 340 PS, Hybrid
                case 442: price += HYBRID + 38;
                    catcar = 6;
                    break;
            }
            break;
        case 2: price += 250;
            switch (INPUT_A_tsn) {

                // Mercedes A

                // 111: Mercedes A 102 PS, Benzin
                case 111: price += PETROL + 32;
                    catcar = 2;
                    break;

                    // 112: Mercedes A 136 PS, Benzin
                case 112: price += PETROL + 34;
                    catcar = 2;
                    break;

                    // 113: Mercedes A 190 PS, Benzin
                case 113: price += PETROL + 40;
                    catcar = 3;
                    break;

                    // 114: Mercedes A 224 PS, Benzin
                case 114: price += PETROL + 44;
                    catcar = 4;
                    break;

                    // 121: Mercedes A 90 PS, Diesel
                case 121: price += DIESEL + 30;
                    catcar = 1;
                    break;

                    // 122: Mercedes A 116 PS, Diesel
                case 122: price += DIESEL + 32;
                    catcar = 2;
                    break;

                    // 123: Mercedes A 136 PS, Diesel
                case 123: price += DIESEL + 34;
                    catcar = 2;
                    break;

                    // 124: Mercedes A 177 PS, Diesel
                case 124: price += DIESEL + 38;
                    catcar = 3;
                    break;

                    // 131: Mercedes A 68 PS, Elektro
                case 131: price += ELECTRO + 28;
                    catcar = 1;
                    break;

                    // Mercedes E

                    // 211: Mercedes E 156 PS, Benzin
                case 211: price += PETROL + 36;
                    catcar = 3;
                    break;

                    // 212: Mercedes E 184 PS, Benzin
                case 212: price += PETROL + 40;
                    catcar = 3;
                    break;

                    // 213: Mercedes E 211 PS, Benzin
                case 213: price += PETROL + 42;
                    catcar = 4;
                    break;

                    // 214: Mercedes E 292 PS, Benzin
                case 214: price += PETROL + 50;
                    catcar = 5;
                    break;

                    // 221: Mercedes E 150 PS, Diesel
                case 221: price += DIESEL + 36;
                    catcar = 2;
                    break;

                    // 222: Mercedes E 160 PS, Diesel
                case 222: price += DIESEL + 36;
                    catcar = 3;
                    break;

                    // 223: Mercedes E 204 PS, Diesel
                case 223: price += DIESEL + 42;
                    catcar = 4;
                    break;

                    // 224: Mercedes E 265 PS, Diesel
                case 224: price += DIESEL + 48;
                    catcar = 5;
                    break;

                    // 231: Mercedes E 194 PS, Elektro
                case 231: price += ELECTRO + 40;
                    catcar = 3;
                    break;

                    // 232: Mercedes E 211 PS, Elektro
                case 232: price += ELECTRO + 42;
                    catcar = 4;
                    break;

                    // 233: Mercedes E 299 PS, Elektro
                case 233: price += ELECTRO + 50;
                    catcar = 5;
                    break;

                    // 234: Mercedes E 435 PS, Elektro
                case 234: price += ELECTRO + 64;
                    catcar = 8;
                    break;

                    // 241: Mercedes E 194 PS, Hybrid
                case 241: price += HYBRID + 40;
                    catcar = 3;
                    break;

                    // 242: Mercedes E 211 PS, Hybrid
                case 242: price += HYBRID + 42;
                    catcar = 4;
                    break;

                    // 243: Mercedes E 299 PS, Hybrid
                case 243: price += HYBRID + 50;
                    catcar = 5;
                    break;

                    // 244: Mercedes E 435 PS, Hybrid
                case 244: price += HYBRID + 64;
                    catcar = 8;
                    break;

                    // Mercedes CLS

                    // 311: Mercedes CLS 299 PS, Benzin
                case 311: price += PETROL + 50;
                    catcar = 5;
                    break;

                    // 312: Mercedes CLS 333 PS, Benzin
                case 312: price += PETROL + 54;
                    catcar = 6;
                    break;

                    // 313: Mercedes CLS 367 PS, Benzin
                case 313: price += PETROL + 58;
                    catcar = 7;
                    break;

                    // 314: Mercedes CLS 435 PS, Benzin
                case 314: price += PETROL + 64;
                    catcar = 8;
                    break;

                    // 321: Mercedes CLS 163 PS, Diesel
                case 321: price += DIESEL + 38;
                    catcar = 3;
                    break;

                    // 322: Mercedes CLS 245 PS, Diesel
                case 322: price += DIESEL + 46;
                    catcar = 4;
                    break;

                    // 323: Mercedes CLS 286 PS, Diesel
                case 323: price += DIESEL + 50;
                    catcar = 5;
                    break;

                    // 324: Mercedes CLS 340 PS, Diesel
                case 324: price += DIESEL + 54;
                    catcar = 6;
                    break;

                    // 331: Mercedes CLS 299 PS, Elektro
                case 331: price += ELECTRO + 50;
                    catcar = 5;
                    break;

                    // 332: Mercedes CLS 367 PS, Elektro
                case 332: price += ELECTRO + 58;
                    catcar = 7;
                    break;

                    // 333: Mercedes CLS 435 PS, Elektro
                case 333: price += ELECTRO + 64;
                    catcar = 8;
                    break;

                    // 341: Mercedes CLS 299 PS, Hybrid
                case 341: price += HYBRID + 50;
                    catcar = 5;
                    break;

                    // 342: Mercedes CLS 367 PS, Hybrid
                case 342: price += HYBRID + 58;
                    catcar = 7;
                    break;

                    // 343: Mercedes CLS 435 PS, Hybrid
                case 343: price += HYBRID + 64;
                    catcar = 8;
                    break;


                    // Mercedes S

                    // 411: Mercedes S 272 PS, Benzin
                case 411: price += PETROL + 48;
                    catcar = 5;
                    break;

                    // 412: Mercedes S 435 PS, Benzin
                case 412: price += PETROL + 64;
                    catcar = 8;
                    break;

                    // 413: Mercedes S 530 PS, Benzin
                case 413: price += PETROL + 74;
                    catcar = 10;
                    break;

                    // 414: Mercedes S 630 PS, Benzin
                case 414: price += PETROL + 84;
                    catcar = 10;
                    break;

                    // 421: Mercedes S 252 PS, Diesel
                case 421: price += DIESEL + 46;
                    catcar = 5;
                    break;

                    // 422: Mercedes S 286 PS, Diesel
                case 422: price += DIESEL + 50;
                    catcar = 5;
                    break;

                    // 423: Mercedes S 340 PS, Diesel
                case 423: price += DIESEL + 54;
                    catcar = 6;
                    break;

                    // 431: Mercedes S 367 PS, Elektro
                case 431: price += ELECTRO + 58;
                    catcar = 7;
                    break;

                    // 432: Mercedes S 435 PS, Elektro
                case 432: price += ELECTRO + 64;
                    catcar = 8;
                    break;

                    // 441: Mercedes S 367 PS, Hybrid
                case 441: price += HYBRID + 58;
                    catcar = 7;
                    break;

                    // 442: Mercedes S 435 PS, Hybrid
                case 442: price += HYBRID + 64;
                    catcar = 8;
                    break;
            }
            break;

        case 3: price += 150;
            switch (INPUT_A_tsn) {

                // Jaguar e-pace

                // 111: Jaguar e-pace 200 PS, Benzin
                case 111: price += PETROL + 40;
                    catcar = 3;
                    break;

                    // 112: Jaguar e-pace 249 PS, Benzin
                case 112: price += PETROL + 46;
                    catcar = 3;
                    break;

                    // 113: Jaguar e-pace 300 PS, Benzin
                case 113: price += PETROL + 50;
                    catcar = 5;
                    break;

                    // 121: Jaguar e-pace 150 PS, Diesel
                case 121: price += DIESEL + 36;
                    catcar = 2;
                    break;

                    // 122: Jaguar e-pace 179 PS, Diesel
                case 122: price += DIESEL + 38;
                    catcar = 3;
                    break;

                    // 123: Jaguar e-pace 241 PS, Diesel
                case 123: price += DIESEL + 46;
                    catcar = 4;
                    break;

                    // Jaguar F-Type

                    // 211: Jaguar F-Type 300 PS, Benzin
                case 211: price += PETROL + 50;
                    catcar = 5;
                    break;

                    // 212: Jaguar F-Type 381 PS, Benzin
                case 212: price += PETROL + 60;
                    catcar = 7;
                    break;

                    // 213: Jaguar F-Type 551 PS, Benzin
                case 213: price += PETROL + 76;
                    catcar = 10;
                    break;

                    // 214: Jaguar F-Type 575 PS, Benzin
                case 214: price += PETROL + 78;
                    catcar = 10;
                    break;

                    // Jaguar i-pace

                    // 311: Jaguar i-pace 234 PS, Elektro
                case 311: price += ELECTRO + 44;
                    catcar = 4;
                    break;

                    // Jaguar xj
                    // 411: Jaguar xj 241 PS, Benzin
                case 411: price += PETROL + 46;
                    catcar = 4;
                    break;

                    // 412: Jaguar xj 385 PS, Benzin
                case 412: price += PETROL + 60;
                    catcar = 7;
                    break;

                    // 413: Jaguar xj 470 PS, Benzin
                case 413: price += PETROL + 68;
                    catcar = 9;
                    break;

                    // 414: Jaguar xj 575 PS, Benzin
                case 414: price += PETROL + 78;
                    catcar = 10;
                    break;

                    // 421: Jaguar xj 300 PS, Diesel
                case 421: price += DIESEL + 50;
                    catcar = 5;
                    break;
            }
            break;
    }

    uint8_t firstlic = INPUT_A_firstlic;

    // Limit first licensation to 30 years
    if (INPUT_A_firstlic > 30) {
        firstlic = 30;
    }

    // steps * 25
    price += (firstlic / 5) * 25;

    // Is car used
    if (firstlic > INPUT_A_takerlic) {
        price += 30;
    } else {
        price += 5;
    }

    struct categorize_car_result result;

    result.OUTPUT_price = price;
    result.OUTPUT_catcar = catcar;

    return result;
}
