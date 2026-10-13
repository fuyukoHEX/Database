-- Sample rows for In-Class Task: Car Rental (run after Task 4)
INSERT INTO cars (car_id, plate_number, brand, year, daily_rate) VALUES
    (1, '777AAA02', 'Toyota',  2022, 25000),
    (2, '123BCD01', 'Hyundai', 2019, 18000);

INSERT INTO clients (client_id, full_name, email, age) VALUES
    (1, 'Askar Bekov', 'askar@mail.kz', 34),
    (2, 'Laura Kim',   NULL,            27);

INSERT INTO rentals (rental_id, car_id, client_id, start_date, end_date) VALUES
    (1, 1, 1, '2026-10-01', '2026-10-05'),
    (2, 1, 2, '2026-10-10', NULL),
    (3, 2, 1, '2026-10-03', '2026-10-04');

