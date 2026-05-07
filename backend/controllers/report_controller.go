package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"gamevault-backend/database"
	"gamevault-backend/models"
)

type gameSummary struct {
	Name   string  `json:"name"`
	Rating float64 `json:"rating"`
}

type reportResponse struct {
	TotalGames      int            `json:"total_games"`
	AverageRating   float64        `json:"average_rating"`
	GamesByGenre    map[string]int `json:"games_by_genre"`
	GamesByPlatform map[string]int `json:"games_by_platform"`
	HighestRated    *gameSummary   `json:"highest_rated"`
	LowestRated     *gameSummary   `json:"lowest_rated"`
}

func GenerateReport(c *gin.Context) {
	var games []models.Game
	if err := database.DB.Find(&games).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	report := reportResponse{
		TotalGames:      len(games),
		GamesByGenre:    map[string]int{},
		GamesByPlatform: map[string]int{},
	}

	if len(games) == 0 {
		c.JSON(http.StatusOK, report)
		return
	}

	var sum float64
	highest := games[0]
	lowest := games[0]

	for _, g := range games {
		sum += g.Rating
		report.GamesByGenre[g.Genre]++
		report.GamesByPlatform[g.Platform]++

		if g.Rating > highest.Rating {
			highest = g
		}
		if g.Rating < lowest.Rating {
			lowest = g
		}
	}

	report.AverageRating = sum / float64(len(games))
	report.HighestRated = &gameSummary{Name: highest.Name, Rating: highest.Rating}
	report.LowestRated = &gameSummary{Name: lowest.Name, Rating: lowest.Rating}

	c.JSON(http.StatusOK, report)
}
