using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> logger;
        private readonly WeatherForecastContext weatherForecastContext;

        public WeatherForecastController(ILogger<WeatherForecastController> logger, WeatherForecastContext weatherForecastContext)
        {
            this.logger = logger;
            this.weatherForecastContext = weatherForecastContext;
        }

        [HttpGet(Name = "GetWeatherForecast")]
        public IEnumerable<WeatherForecastRequest> Get()
        {
            return Enumerable.Range(1, 5).Select(index => new WeatherForecastRequest
            {
                Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<WeatherForecastRequest>> GetById(int id)
        {
            var result = await weatherForecastContext.FindAsync<WeatherForecast>(id);

            return result is null ? NotFound() : new WeatherForecastRequest { Date = DateOnly.FromDateTime(result.Date), TemperatureC = result.TemperatureC, Summary = result.Summary };
        }

        [HttpPost]
        public async Task<ActionResult<WeatherForecastRequest>> Create(WeatherForecastRequest forecast)
        {
            weatherForecastContext.Add(new WeatherForecast
            {
                Date = forecast.Date.ToDateTime(TimeOnly.MinValue),
                TemperatureC = forecast.TemperatureC,
                Summary = forecast.Summary,
            });

            await weatherForecastContext.SaveChangesAsync();

            return Created();
        }
    }
}
