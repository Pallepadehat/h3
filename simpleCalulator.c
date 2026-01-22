#include "stdio.h"
#include "stdlib.h"
#include "unistd.h"

// ANSI Farvekoder
#define CYAN    "\033[1;36m"
#define GREEN   "\033[1;32m"
#define YELLOW  "\033[1;33m"
#define RED     "\033[1;31m"
#define RESET   "\033[0m"
#define BOLD    "\033[1m"


void clear_screen() {
  printf("\033[1;1H\033[2J");
}

void print_header() {
    clear_screen();
    printf(CYAN "==========================================\n");
    printf("           BEST CALCULATOR EVER MADE           \n");
    printf("==========================================\n" RESET);
    printf("\n");
}

int main() {
    char operator;
    double num1, num2, result;
    int running = 1;

    while (running) {
        print_header();
        
        // 1. Menu
        printf(GREEN " [OPTIONS] \n" RESET);
        printf("  (+) Addition\n");
        printf("  (-) Subtraction\n");
        printf("  (*) Multiplication\n");
        printf("  (/) Division\n");
        printf("  (q) Quit\n\n");
        
        printf(YELLOW " > Select Operation: " RESET);
        scanf(" %c", &operator);

        // Hvis brugeren vil stoppe
        if (operator == 'q') {
            printf(RED "\n [SYSTEM SHUTDOWN...]\n" RESET);
            break;
        }

        // 2. Input af tal
        printf(YELLOW " > Enter first number:  " RESET);
        if (scanf("%lf", &num1) != 1) { // Validering
            printf(RED " Invalid input!\n" RESET);
            getchar(); getchar(); continue; 
        }

        printf(YELLOW " > Enter second number: " RESET);
        if (scanf("%lf", &num2) != 1) {
            printf(RED " Invalid input!\n" RESET);
            getchar(); getchar(); continue;
        }

        // 3. Beregning
        int valid = 1;
        switch (operator) {
            case '+': result = num1 + num2; break;
            case '-': result = num1 - num2; break;
            case '*': result = num1 * num2; break;
            case '/': 
                if (num2 == 0) {
                    printf(RED "\n [ERROR] Division by zero detected!\n" RESET);
                    valid = 0;
                } else {
                    result = num1 / num2; 
                }
                break;
            default:
                printf(RED "\n [ERROR] Unknown operation!\n" RESET);
                valid = 0;
        }

        // 4. Vis Resultat
        if (valid) {
            printf("\n" CYAN "==========================================\n" RESET);
            printf(GREEN " RESULT: " BOLD "%.2lf" RESET "\n", result);
            printf(CYAN "==========================================\n" RESET);
        }

        // Vent på brugeren før vi starter forfra
        printf("\n Press ENTER to continue...");
        getchar(); // Fanger den sidste 'enter'
        getchar(); // Venter på nyt tryk
    }

    return 0;
}

