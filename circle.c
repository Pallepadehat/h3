#include <math.h>
#include <stdio.h>

int main() {
  int radius = 20;
  float aspect_ratio = 0.75; // Compares char width vs height

  for (int i = 0; i <= 2 * radius; i++) {
    for (int j = 0; j <= 2 * radius; j++) {
      // Center the coordinates
      double y = (double)(i - radius);
      double x = (double)(j - radius) * aspect_ratio;

      double distance = sqrt(x * x + y * y);

      // Using a threshold to create the "ring" effect
      // We scale the radius comparison by the aspect ratio as well
      if (distance > (radius * aspect_ratio) - 0.4 &&
          distance < (radius * aspect_ratio) + 0.4) {
        printf("* "); // Two characters wide
      } else {
        printf("  "); // Two characters wide
      }
    }
    printf("\n");
  }
  return 0;
}