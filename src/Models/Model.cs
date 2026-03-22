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
