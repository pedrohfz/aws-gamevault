package models

import "time"

type Game struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" binding:"required"`
	Genre       string    `json:"genre" binding:"required"`
	Platform    string    `json:"platform" binding:"required"`
	Rating      float64   `json:"rating" binding:"required,min=0,max=10"`
	ReleaseYear int       `json:"release_year" binding:"required"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
