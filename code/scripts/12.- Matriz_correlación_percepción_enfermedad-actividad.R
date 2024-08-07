# Configurar el directorio de trabajo
if (.Platform$OS.type == "windows") {
  setwd("C:/Users/FX506/Documents/Portafolio/Bellabeat_2016")
} else {
  setwd("~/Portafolio/Bellabeat_2016")
}

# Limpiar el entorno
rm(list = ls())
gc()

# Instalar y cargar paquetes necesarios
if(!require(corrplot)) install.packages("corrplot")
if(!require(car)) install.packages("car")
if(!require(ggplot2)) install.packages("ggplot2")

library(readxl)
library(dplyr)
library(stringr)
library(janitor)
library(car)
library(ggplot2)
library(corrplot)

# Definir la ruta del archivo
file_path <- "data/minsa/raw/datos_ense2017_resumen.xls"
output_folder <- "output/minsa"

# Leer y limpiar los datos
percepcion_salud <- read_excel(file_path, sheet = "T1001_estado_de_salud", range = "A1:F9", col_types = "text")
percepcion_salud_clean <- percepcion_salud %>%
  janitor::clean_names() %>%
  mutate(across(muy_bueno:muy_malo, ~ as.numeric(str_replace_all(., ",", "."))))
colnames(percepcion_salud_clean) <- c("grupo_etareo", "muy_bueno", "bueno", "regular", "malo", "muy_malo")

enfermedades_cronicas <- read_excel(file_path, sheet = "T1025_enfermedades_cronicas", range = "A1:AF9", col_types = "text")
enfermedades_cronicas <- enfermedades_cronicas %>%
  select(mujeres, tensión_alta, artrosis, dolor_espalda_cervical, dolor_espalda_lumbar, diabetes, colesterol_alto)
enfermedades_cronicas_clean <- enfermedades_cronicas %>%
  janitor::clean_names() %>%
  mutate(across(-mujeres, ~ as.numeric(str_replace_all(., ",", "."))))
colnames(enfermedades_cronicas_clean)[1] <- "grupo_etareo"

actividad_fisica <- read_excel(file_path, sheet = "T3066_nivel_actividad_fisica", range = "A1:D9", col_types = "text")
actividad_fisica_clean <- actividad_fisica %>%
  janitor::clean_names() %>%
  mutate(across(nivel_alto:nivel_bajo, ~ as.numeric(str_replace_all(., ",", "."))))
colnames(actividad_fisica_clean)[1] <- "grupo_etareo"

# Combinar los datos
datos_combinados <- percepcion_salud_clean %>%
  inner_join(enfermedades_cronicas_clean, by = "grupo_etareo") %>%
  inner_join(actividad_fisica_clean, by = "grupo_etareo")

# Calcular y visualizar la matriz de correlación
datos_numericos <- datos_combinados %>% select(-grupo_etareo)
matriz_correlacion <- cor(datos_numericos, use = "complete.obs")
corrplot(matriz_correlacion, method = "color", tl.cex = 0.7, tl.col = "black")

# Guardar la matriz de correlación en un archivo .rds
saveRDS(matriz_correlacion, file.path(output_folder, "matriz_correlacion.rds"))

# Ajustar el modelo de regresión excluyendo variables altamente correlacionadas
modelo <- lm(nivel_bajo ~ muy_bueno + bueno + malo + muy_malo + tension_alta + artrosis, data = datos_combinados)

# Guardar el resumen del modelo de regresión en un archivo .rds
saveRDS(summary(modelo), file.path(output_folder, "modelo_regresion.rds"))

# Detectar multicolinealidad
vif_values <- vif(modelo)
print(vif_values)

# Resumen del modelo de regresión
summary(modelo)

# Generar predicciones y residuos
predicciones <- predict(modelo, datos_combinados)
residuos <- residuals(modelo)

# Visualizar predicciones vs residuos
ggplot(data.frame(predicciones, residuos), aes(x = predicciones, y = residuos)) +
  geom_point() +
  geom_hline(yintercept = 0, col = "red") +
  labs(title = "Residuos vs. Valores ajustados", x = "Valores Ajustados", y = "Residuos") +
  theme_minimal()
