using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using WebApi.Models;

namespace WebApi
{
    public class WeatherForecastContextFactory : IDesignTimeDbContextFactory<WeatherForecastContext>
    {
        public WeatherForecastContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<WeatherForecastContext>();

            optionsBuilder.UseSqlServer("Server=(localdb)\\mssqllocaldb;Database=design_time_db;Trusted_Connection=True;");

            return new WeatherForecastContext(optionsBuilder.Options);
        }
    }
}
