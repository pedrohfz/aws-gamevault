package database

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"gamevault-backend/models"
)

var DB *gorm.DB

func Connect() {
	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "prefer"
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=UTC",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		sslmode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("falha ao conectar ao banco de dados: %v", err)
	}

	if err := db.AutoMigrate(&models.Game{}); err != nil {
		log.Fatalf("falha ao migrar schema: %v", err)
	}

	DB = db
	log.Println("conexão com PostgreSQL estabelecida")
}
