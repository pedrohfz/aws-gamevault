package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"gamevault-backend/database"
	"gamevault-backend/models"
)

func ListGames(c *gin.Context) {
	var games []models.Game
	if err := database.DB.Find(&games).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, games)
}

func GetGame(c *gin.Context) {
	id := c.Param("id")
	var game models.Game
	if err := database.DB.First(&game, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "jogo não encontrado"})
		return
	}
	c.JSON(http.StatusOK, game)
}

func CreateGame(c *gin.Context) {
	var game models.Game
	if err := c.ShouldBindJSON(&game); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := database.DB.Create(&game).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, game)
}

func UpdateGame(c *gin.Context) {
	id := c.Param("id")
	var game models.Game
	if err := database.DB.First(&game, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "jogo não encontrado"})
		return
	}

	var input models.Game
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	game.Name = input.Name
	game.Genre = input.Genre
	game.Platform = input.Platform
	game.Rating = input.Rating
	game.ReleaseYear = input.ReleaseYear

	if err := database.DB.Save(&game).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, game)
}

func DeleteGame(c *gin.Context) {
	id := c.Param("id")
	var game models.Game
	if err := database.DB.First(&game, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "jogo não encontrado"})
		return
	}
	if err := database.DB.Delete(&game).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "jogo removido"})
}
