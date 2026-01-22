#include <stdio.h>
#include <stdlib.h>
#include <unistd.h> // usleep
#include <termios.h> // Terminal kontrol
#include <fcntl.h>   // File control
#include <time.h>    // Random seed

// --- KONFIGURATION ---
#define WIDTH 40
#define HEIGHT 20
#define DELAY 100000 // Spillets hastighed (mikrosekunder)

// Farver
#define GREEN "\033[32m"
#define RED   "\033[31m"
#define BLUE  "\033[34m"
#define RESET "\033[0m"

// Definerer et punkt (x, y)
typedef struct {
    int x;
    int y;
} Point;

// Globale variabler
Point snake[100]; // Slangen kan blive max 100 lang
int snakeLen = 5; // Start længde
Point food;
int score = 0;
int gameOver = 0;
int dirX = 1;     // Start retning (mod højre)
int dirY = 0;

// --- UNIX MAGI: Non-blocking Input ---
// Dette gør at vi kan tjekke om en knap er trykket UDEN at pause programmet
int kbhit(void) {
    struct termios oldt, newt;
    int ch;
    int oldf;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);
    if(ch != EOF) {
        ungetc(ch, stdin);
        return 1;
    }
    return 0;
}

// --- SPIL LOGIK ---

void setup() {
    // Start position (midten)
    snake[0].x = WIDTH / 2;
    snake[0].y = HEIGHT / 2;
    
    // Generer første mad
    srand(time(0));
    food.x = rand() % (WIDTH - 2) + 1;
    food.y = rand() % (HEIGHT - 2) + 1;
    
    // Skjul cursor
    printf("\033[?25l");
}

void draw() {
    // Flyt cursor til toppen i stedet for at clear (fjerner flimren)
    printf("\033[H"); 

    // Tegn toppen
    printf(BLUE);
    for(int i = 0; i < WIDTH+2; i++) printf("#");
    printf("\n");

    for (int y = 0; y < HEIGHT; y++) {
        printf("#"); // Venstre væg
        for (int x = 0; x < WIDTH; x++) {
            
            int printed = 0;
            
            // Er det hovedet?
            if (x == snake[0].x && y == snake[0].y) {
                printf(GREEN "O" BLUE); // Hoved
                printed = 1;
            }
            // Er det maden?
            else if (x == food.x && y == food.y) {
                printf(RED "@" BLUE); // Mad
                printed = 1;
            }
            // Er det kroppen?
            else {
                for (int k = 1; k < snakeLen; k++) {
                    if (snake[k].x == x && snake[k].y == y) {
                        printf(GREEN "o" BLUE);
                        printed = 1;
                        break;
                    }
                }
            }
            
            if (!printed) printf(" ");
        }
        printf("#\n"); // Højre væg
    }

    // Tegn bunden
    for(int i = 0; i < WIDTH+2; i++) printf("#");
    printf(RESET "\n");
    printf(" Score: %d  (Controls: W A S D, Q to quit)\n", score);
}

void input() {
    if (kbhit()) {
        char c = getchar();
        switch(c) {
            case 'a': if(dirX != 1)  { dirX = -1; dirY = 0; } break; // Venstre
            case 'd': if(dirX != -1) { dirX = 1;  dirY = 0; } break; // Højre
            case 'w': if(dirY != 1)  { dirX = 0;  dirY = -1; } break; // Op
            case 's': if(dirY != -1) { dirX = 0;  dirY = 1; }  break; // Ned
            case 'q': gameOver = 1; break;
        }
    }
}

void logic() {
    // 1. Flyt halen (start bagfra)
    // Hvert led indtager pladsen foran sig
    for (int i = snakeLen - 1; i > 0; i--) {
        snake[i] = snake[i-1];
    }

    // 2. Flyt hovedet
    snake[0].x += dirX;
    snake[0].y += dirY;

    // 3. Tjek kollision med vægge
    if (snake[0].x < 0 || snake[0].x >= WIDTH || snake[0].y < 0 || snake[0].y >= HEIGHT) {
        gameOver = 1;
    }

    // 4. Tjek kollision med sig selv
    for (int i = 1; i < snakeLen; i++) {
        if (snake[0].x == snake[i].x && snake[0].y == snake[i].y) {
            gameOver = 1;
        }
    }

    // 5. Spis mad
    if (snake[0].x == food.x && snake[0].y == food.y) {
        score += 10;
        snakeLen++;
        // Ny mad position
        food.x = rand() % (WIDTH - 2) + 1;
        food.y = rand() % (HEIGHT - 2) + 1;
    }
}

int main() {
    setup();
    
    // Clear skærmen én gang i starten
    printf("\033[2J"); 

    while (!gameOver) {
        draw();
        input();
        logic();
        usleep(DELAY); // Vent lidt (så spillet ikke kører med lynets hast)
    }

    // Reset cursor og farver når vi er færdige
    printf("\033[?25h"); // Vis cursor igen
    printf(RED "\n GAME OVER! Final Score: %d\n" RESET, score);
    
    return 0;
}

