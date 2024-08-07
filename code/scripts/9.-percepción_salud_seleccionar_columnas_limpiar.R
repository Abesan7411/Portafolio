# Configurar el directorio de trabajo
if (.Platform$OS.type == "windows") {
  setwd("C:/Users/FX506/Documents/Portafolio/Bellabeat_2016")
} else {
  setwd("~/Portafolio/Bellabeat_2016")
}

# Limpiar el entorno
rm(list = ls())
gc()

# Cargar librerías
library(readxl)
library(tidyverse)
library(janitor)

# Definir la ruta del archivo Excel
file_path <- "data/minsa/raw/datos_ense2017_resumen.xls"

# Leer el archivo Excel y seleccionar el rango de datos
estado_de_salud <- read_excel(file_path, sheet = "T1001_estado_de_salud", range = "A1:F9", col_types = "text")

# Limpiar nombres de columnas
estado_de_salud_clean <- estado_de_salud %>%
  janitor::clean_names()

# Convertir las columnas numéricas a numéricas y reemplazar comas por puntos
estado_de_salud_clean <- estado_de_salud_clean %>%
  mutate(across(muy_bueno:muy_malo, ~ as.numeric(str_replace_all(., ",", "."))))

# Inspeccionar la estructura de los datos limpiados
str(estado_de_salud_clean)
head(estado_de_salud_clean)
summary(estado_de_salud_clean)

# Reorganizar los datos en un formato adecuado para graficar
estado_de_salud_mujeres_melted <- estado_de_salud_clean %>%
  pivot_longer(cols = muy_bueno:muy_malo, names_to = "nivel_percepcion", values_to = "porcentaje")

# Normalizar los datos dentro de cada grupo etario
estado_de_salud_mujeres_melted <- estado_de_salud_mujeres_melted %>%
  group_by(mujeres) %>%
  mutate(porcentaje = porcentaje / sum(porcentaje, na.rm = TRUE) * 100) %>%
  ungroup()

# Crear el gráfico de barras
estado_de_salud_mujeres_melted %>%
  ggplot(aes(x = mujeres, y = porcentaje, fill = nivel_percepcion)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Percepción del estado de salud en mujeres por grupo etario",
       x = "Grupo Etareo",
       y = "Porcentaje",
       fill = "Nivel de Percepción") +
  theme_minimal()
