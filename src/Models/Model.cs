using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;

namespace WebApi.Models
{
    public class WeatherForecastContext : DbContext
    {
        public WeatherForecastContext(DbContextOptions<WeatherForecastContext> options)
        : base(options)
        {
        }

        public DbSet<WeatherForecast> WeatherForecasts { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<WeatherForecast>().HasData(
                new WeatherForecast { WeatherForecastId = 1, Date = DateTime.Today, TemperatureC = 10, Summary = "Cold" },
                new WeatherForecast { WeatherForecastId = 2, Date = DateTime.Today, TemperatureC = 20, Summary = "Mild" },
                new WeatherForecast { WeatherForecastId = 3, Date = DateTime.Today, TemperatureC = 30, Summary = "Warm" }
            );
        }
    }

    public class WeatherForecast
    {
        public int WeatherForecastId { get; set; }
        public DateTime Date { get; set; }
        public int TemperatureC { get; set; }
        public string Summary { get; set; }
        public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    }
}
